import 'package:businesssajilo/core/config/env.dart';
import 'package:businesssajilo/data/remote/supabase_bills_repository.dart';
import 'package:businesssajilo/data/remote/supabase_members_repository.dart';
import 'package:businesssajilo/data/remote/supabase_orders_repository.dart';
import 'package:businesssajilo/data/remote/supabase_payments_repository.dart';
import 'package:businesssajilo/data/remote/supabase_products_repository.dart';
import 'package:businesssajilo/data/repositories/bills_repository.dart';
import 'package:businesssajilo/data/repositories/orders_repository.dart';
import 'package:businesssajilo/data/repositories/quotes_repository.dart';
import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/domain/models/order.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../support/hardening_gate.dart';
import 'support/bootstrap.dart';

/// Repository integration (not UI): order → quote → accept → bill against local
/// Supabase. Classified as remote repository coverage; see
/// `ui_order_to_bill_flow_test.dart` for the widget-driven path.
void main() {
  late bool supabaseAvailable;

  setUpAll(() async {
    supabaseAvailable = await isSupabaseAvailable();
  });

  test('order → quote → accept → bill via repositories', () async {
    if (!Env.isConfigured) {
      requireForHardeningGate(
        false,
        'Set SUPABASE_URL and SUPABASE_ANON_KEY dart-defines',
      );
      return;
    }
    if (!supabaseAvailable) {
      requireForHardeningGate(
        false,
        'Supabase not reachable — run: supabase start',
      );
      return;
    }

    if (!_supabaseReady) {
      await Supabase.initialize(
        url: Env.supabaseUrl,
        publishableKey: Env.supabaseAnonKey,
      );
      _supabaseReady = true;
    }

    final client = Supabase.instance.client;
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
    final Order order = await customerOrders.placeOrder(
      customerId: created.customerId!,
      lines: [OrderLineInput(productId: product.id, qty: 2)],
    );
    expect(order.status, OrderStatus.placed);

    await client.auth.signInWithPassword(
      email: ownerEmail,
      password: ownerPassword,
    );
    final quotes = QuotesRepository(client);
    final ownerMemberId =
        (await client
                .from('members')
                .select('id')
                .eq('auth_user_id', client.auth.currentUser!.id)
                .single())['id']
            as String;
    final quote = await quotes.sendQuote(
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
    expect(quote.status, QuoteStatus.sent);

    await client.auth.signInWithPassword(
      email: customerEmail,
      password: customerPassword,
    );
    final accepted = await QuotesRepository(client).accept(quote.id);
    expect(accepted.status, QuoteStatus.accepted);

    await client.auth.signInWithPassword(
      email: ownerEmail,
      password: ownerPassword,
    );
    final bills = SupabaseBillsRepository(
      client,
      SupabasePaymentsRepository(client),
    );
    final bill = await bills.createFromOrder(
      orderId: order.id,
      customerId: created.customerId!,
      createdByMemberId: ownerMemberId,
      status: BillStatus.due,
      itemsTotal: 1000,
      discount: 0,
      grandTotal: 1000,
      lines: [
        BillLineInput(
          productId: product.id,
          nameSnapshot: product.name,
          qty: 2,
          rate: 500,
          lineTotal: 1000,
        ),
      ],
    );
    expect(bill.orderId, order.id);
    expect(bill.grandTotal, 1000);
    expect(bill.status, BillStatus.due);
  });
}

bool _supabaseReady = false;
