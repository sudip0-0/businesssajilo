import 'package:businesssajilo/data/local/app_database.dart';
import 'package:businesssajilo/data/remote/supabase_customers_repository.dart';
import 'package:businesssajilo/data/sync/cached_customers_repository.dart';
import 'package:businesssajilo/data/sync/pull/sync_pull_entities.dart';
import 'package:businesssajilo/domain/models/ledger_entry.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _LedgerRemote extends SupabaseCustomersRepository {
  _LedgerRemote(this.entries) : super(null);

  final List<LedgerEntry> entries;

  @override
  Future<List<LedgerEntry>> ledger(
    String customerId, {
    int offset = 0,
    int? limit,
  }) async {
    if (limit != null) {
      if (offset >= entries.length) return const [];
      final end = (offset + limit).clamp(0, entries.length);
      return entries.sublist(offset, end);
    }
    return entries;
  }
}

class _FailingLedgerRemote extends SupabaseCustomersRepository {
  _FailingLedgerRemote() : super(null);

  @override
  Future<List<LedgerEntry>> ledger(
    String customerId, {
    int offset = 0,
    int? limit,
  }) async {
    throw Exception('offline');
  }
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedCustomer({int balanceDue = 165500}) async {
    await db
        .into(db.localCustomers)
        .insert(
          LocalCustomersCompanion.insert(
            id: 'c1',
            businessId: 'biz',
            memberId: 'm',
            shopName: 'Shop 02',
            openingBalance: const Value(0),
            balanceDue: Value(balanceDue),
            updatedAt: DateTime.utc(2026, 1, 1),
            createdAt: Value(DateTime.utc(2026, 1, 1)),
          ),
        );
  }

  test('ledger merges local payment missing from remote', () async {
    await seedCustomer();
    await db
        .into(db.localPayments)
        .insert(
          LocalPaymentsCompanion.insert(
            id: 'pay-local',
            businessId: 'biz',
            customerId: 'c1',
            amount: 5000,
            method: 'cash',
            receivedBy: 'm',
            createdAt: Value(DateTime.utc(2026, 8, 14)),
          ),
        );

    final remoteBill = LedgerEntry(
      customerId: 'c1',
      businessId: 'biz',
      occurredAt: DateTime.utc(2026, 8, 1),
      entryType: 'bill',
      description: 'B-1',
      debitPaisa: 165500,
      refId: 'bill-1',
    );
    final repo = CachedCustomersRepository(
      db: db,
      remote: _LedgerRemote([remoteBill]),
    );

    final entries = await repo.ledger('c1');
    expect(entries.map((e) => e.refId).toList(), ['bill-1', 'pay-local']);
    expect(entries.last.creditPaisa, 5000);
    expect(entries.last.runningBalance, 160500);
  });

  test('offline ledger is built from local bills and payments', () async {
    await seedCustomer(balanceDue: 1000);
    await db
        .into(db.localBills)
        .insert(
          LocalBillsCompanion.insert(
            id: 'bill-1',
            businessId: 'biz',
            customerId: const Value('c1'),
            billNo: 'B-1',
            status: 'due',
            createdBy: 'm',
            grandTotal: const Value(1000),
            createdAt: Value(DateTime.utc(2026, 8, 1)),
          ),
        );
    await db
        .into(db.localPayments)
        .insert(
          LocalPaymentsCompanion.insert(
            id: 'pay-1',
            businessId: 'biz',
            customerId: 'c1',
            amount: 400,
            method: 'cash',
            receivedBy: 'm',
            createdAt: Value(DateTime.utc(2026, 8, 2)),
          ),
        );

    final repo = CachedCustomersRepository(
      db: db,
      remote: _FailingLedgerRemote(),
    );
    final entries = await repo.ledger('c1');
    expect(entries.map((e) => e.entryType).toList(), ['bill', 'payment']);
    expect(entries.last.runningBalance, 600);
  });

  test(
    'customer pull keeps optimistic balance while payment is pending',
    () async {
      await seedCustomer(balanceDue: 950);
      await db
          .into(db.localPayments)
          .insert(
            LocalPaymentsCompanion.insert(
              id: 'pay-local',
              businessId: 'biz',
              customerId: 'c1',
              amount: 50,
              method: 'cash',
              receivedBy: 'm',
              syncStatus: const Value('pending'),
            ),
          );

      final entities = SyncPullEntities(
        db: db,
        client: SupabaseClient('http://localhost', 'anon'),
      );
      await entities.upsertCustomerBalancesBatch([
        {
          'customer_id': 'c1',
          'business_id': 'biz',
          'member_id': 'm',
          'shop_name': 'Shop 02',
          'balance_due': 1000,
          'opening_balance': 0,
          'updated_at': '2026-08-14T00:00:00Z',
        },
      ]);

      final row = await (db.select(
        db.localCustomers,
      )..where((c) => c.id.equals('c1'))).getSingle();
      expect(row.balanceDue, 950);
    },
  );
}
