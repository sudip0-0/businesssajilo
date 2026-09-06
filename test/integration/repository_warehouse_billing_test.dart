import 'package:businesssajilo/core/config/env.dart';
import 'package:businesssajilo/data/remote/supabase_bills_repository.dart';
import 'package:businesssajilo/data/remote/supabase_customers_repository.dart';
import 'package:businesssajilo/data/remote/supabase_members_repository.dart';
import 'package:businesssajilo/data/remote/supabase_payments_repository.dart';
import 'package:businesssajilo/data/repositories/bills_repository.dart';
import 'package:businesssajilo/domain/enums.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../support/hardening_gate.dart';

void main() {
  test(
    'warehouse selects a customer and reopens a bill without finance access',
    () async {
      requireForHardeningGate(
        Env.isConfigured,
        'Warehouse integration needs local Supabase and create-member',
      );
      if (!Env.isConfigured) return;
      final host = Uri.parse(Env.supabaseUrl).host;
      expect(
        host,
        isIn(['localhost', '127.0.0.1', '::1']),
        reason:
            'This test creates fixtures and must only run on local Supabase',
      );

      final client = SupabaseClient(Env.supabaseUrl, Env.supabaseAnonKey);
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
      final customers = SupabaseCustomersRepository(client);
      final ownerCustomers = await customers.list(limit: 1);
      expect(
        ownerCustomers,
        isNotEmpty,
        reason: 'Local E2E customers are required',
      );
      final customer = ownerCustomers.single;
      final suffix = const Uuid().v4();
      final warehouseEmail = 'warehouse-$suffix@test.com';
      final warehousePassword = const Uuid().v4();
      final member = await SupabaseMembersRepository(client).createMember(
        email: warehouseEmail,
        password: warehousePassword,
        role: Role.warehouse,
        displayName: 'Warehouse privacy test',
      );
      await client.auth.signInWithPassword(
        email: warehouseEmail,
        password: warehousePassword,
      );

      final directory = await customers.list(includeBalances: false, limit: 5);
      expect(directory, isNotEmpty);
      final selected = await customers.get(customer.id, includeBalances: false);
      expect(selected.shopName, customer.shopName);
      expect(selected.openingBalance, 0);
      expect(selected.balanceDue, 0);
      expect(await client.from('customers').select('opening_balance'), isEmpty);
      expect(await client.from('customer_balances').select(), isEmpty);
      expect(await client.from('customer_ledger_entries').select(), isEmpty);
      expect(await client.from('payments').select(), isEmpty);

      final bills = SupabaseBillsRepository(
        client,
        SupabasePaymentsRepository(client),
      );
      final created = await bills.create(
        createdByMemberId: member.memberId,
        customerId: customer.id,
        status: BillStatus.due,
        itemsTotal: 2510,
        discount: 0,
        grandTotal: 2510,
        lines: const [
          BillLineInput(
            productId: '',
            nameSnapshot: 'Warehouse privacy test item',
            qty: 1,
            rate: 2510,
            lineTotal: 2510,
          ),
        ],
      );
      expect(created.customerShopName, customer.shopName);
      expect(created.status, BillStatus.due);
      expect(created.billNo, startsWith('BS-'));
      final reopened = await bills.get(created.id);
      expect(reopened.customerShopName, customer.shopName);
      expect(reopened.grandTotal, 2510);
      expect(reopened.items.single.nameSnapshot, 'Warehouse privacy test item');
      expect(reopened.items.single.lineTotal, 2510);
      final listed = await bills.list(limit: 1);
      expect(listed.single.id, created.id);
      expect(listed.single.customerShopName, customer.shopName);
      final searched = await bills.search(customer.shopName, limit: 1);
      expect(searched.single.id, created.id);
      expect(searched.single.customerShopName, customer.shopName);
      expect(await client.from('payments').select(), isEmpty);
    },
  );
}
