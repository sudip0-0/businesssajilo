import 'package:businesssajilo/core/config/env.dart';
import 'package:businesssajilo/data/remote/supabase_bills_repository.dart';
import 'package:businesssajilo/data/remote/supabase_members_repository.dart';
import 'package:businesssajilo/data/remote/supabase_orders_repository.dart';
import 'package:businesssajilo/data/remote/supabase_payments_repository.dart';
import 'package:businesssajilo/data/remote/supabase_products_repository.dart';
import 'package:businesssajilo/data/repositories/quotes_repository.dart';
import 'package:businesssajilo/features/billing/create_bill_from_order.dart';
import 'package:businesssajilo/data/repositories/orders_repository.dart';
import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/domain/models/order.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../support/hardening_gate.dart';
import 'support/bootstrap.dart';

/// Repository integration: order → quote versions → accept → bill against local Supabase.
void main() {
  late bool supabaseAvailable;

  setUpAll(() async {
    supabaseAvailable = await isSupabaseAvailable();
  });

  test(
    'order → quote versions → accept → bill via live repositories',
    () async {
      if (!Env.isConfigured) {
        requireForHardeningGate(
          false,
          'Set SUPABASE_URL and SUPABASE_ANON_KEY dart-defines',
        );
        return;
      }
      expect(
        ['127.0.0.1', 'localhost', '::1'],
        contains(Uri.parse(Env.supabaseUrl).host),
        reason: 'Live fixtures are local-only',
      );
      if (!supabaseAvailable) {
        requireForHardeningGate(
          false,
          'Supabase not reachable — run: supabase start',
        );
        return;
      }

      final client = SupabaseClient(
        Env.supabaseUrl,
        Env.supabaseAnonKey,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      addTearDown(client.dispose);
      const ownerEmail = String.fromEnvironment(
        'E2E_EMAIL',
        defaultValue: 'e2e-owner@test.com',
      );
      const ownerPassword = String.fromEnvironment(
        'E2E_PASSWORD',
        defaultValue: 'password123',
      );

      await client.auth.signInWithPassword(
        email: ownerEmail,
        password: ownerPassword,
      );

      final members = SupabaseMembersRepository(client);
      final products = SupabaseProductsRepository(client);
      final suffix = const Uuid().v4().substring(0, 8);
      final customerEmail = 'e2e-cust-$suffix@test.com';
      const customerPassword = 'password123';

      final created = await members.createMember(
        email: customerEmail,
        password: customerPassword,
        role: Role.customer,
        displayName: 'E2E Customer $suffix',
        shopName: 'E2E Shop $suffix',
      );
      expect(created.customerId, isNotNull);

      final product = await products.create(
        name: 'E2E Widget $suffix',
        unit: 'piece',
        costPrice: 100,
        referencePrice: 500,
        lowStockThreshold: 0,
      );

      await client.auth.signInWithPassword(
        email: customerEmail,
        password: customerPassword,
      );
      final customerOrders = SupabaseOrdersRepository(client);
      final orderId = const Uuid().v4();
      final replays = await Future.wait(
        List.generate(
          2,
          (_) => customerOrders.placeOrder(
            id: orderId,
            customerId: created.customerId!,
            lines: [OrderLineInput(productId: product.id, qty: 2)],
          ),
        ),
      );
      final Order order = replays.first;
      expect(replays.map((value) => value.id).toSet(), {orderId});
      expect(order.items, hasLength(1));
      expect(order.status, OrderStatus.placed);

      await client.auth.signInWithPassword(
        email: ownerEmail,
        password: ownerPassword,
      );
      final ownerOrders = SupabaseOrdersRepository(client);
      final ownerMemberId =
          (await client
                  .from('members')
                  .select('id')
                  .eq('auth_user_id', client.auth.currentUser!.id)
                  .single())['id']
              as String;

      final received = await ownerOrders.updateStatus(
        order.id,
        OrderStatus.received,
      );
      expect(received.status, OrderStatus.received);

      final quotes = QuotesRepository(client);
      await quotes.sendQuote(
        orderId: order.id,
        createdByMemberId: ownerMemberId,
        total: 1000,
        lines: [
          QuoteLineInput(
            productId: product.id,
            qty: 2,
            rate: 500,
            lineTotal: 1000,
          ),
        ],
      );
      final revised = await quotes.sendQuote(
        orderId: order.id,
        createdByMemberId: ownerMemberId,
        total: 3740,
        lines: [
          QuoteLineInput(
            productId: product.id,
            qty: 3,
            rate: 1255,
            discount: 25,
            lineTotal: 3740,
          ),
        ],
      );
      expect(revised.version, 2);
      await client.auth.signInWithPassword(
        email: customerEmail,
        password: customerPassword,
      );
      final accepted = await Future.wait(
        List.generate(2, (_) => quotes.accept(revised.id)),
      );
      expect(
        accepted.map((quote) => quote.status),
        everyElement(QuoteStatus.accepted),
      );
      await client.auth.signInWithPassword(
        email: ownerEmail,
        password: ownerPassword,
      );
      final draft = await loadBillFromOrderRepositories(
        orderId: order.id,
        orders: ownerOrders,
        quotes: quotes,
        products: products,
      );
      expect(draft!.lines.single.qty, 3);
      expect(draft.lines.single.rate, 1255);
      expect(draft.lines.single.discount, 25);

      final bills = SupabaseBillsRepository(
        client,
        SupabasePaymentsRepository(client),
      );
      final bill = await bills.createFromOrder(
        orderId: order.id,
        customerId: created.customerId!,
        createdByMemberId: ownerMemberId,
        status: BillStatus.due,
        itemsTotal: draft.itemsTotal,
        discount: draft.discount,
        grandTotal: draft.grandTotal,
        lines: draft.lines,
      );
      expect(bill.orderId, order.id);
      expect(bill.grandTotal, 3740);
      final reopened = await bills.get(bill.id);
      expect(reopened.items.single.qty, 3);
      expect(reopened.items.single.rate, 1255);
      expect(reopened.items.single.discount, 25);
      expect(bill.status, BillStatus.due);

      final billed = await ownerOrders.get(order.id);
      expect(billed.status, OrderStatus.billed);
    },
  );
}
