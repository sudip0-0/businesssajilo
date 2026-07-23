import 'package:businesssajilo/data/local/app_database.dart';
import 'package:businesssajilo/data/repositories/bills_repository.dart';
import 'package:businesssajilo/data/repositories/payments_repository.dart';
import 'package:businesssajilo/data/sync/sync_service.dart';
import 'package:businesssajilo/data/sync/syncing_bills_repository.dart';
import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/domain/models/payment.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakePaymentsRepository implements PaymentsRepository {
  @override
  Future<List<Payment>> listByCustomer(
    String customerId, {
    int offset = 0,
    int limit = 50,
  }) async => const [];

  @override
  Future<Payment> record({
    String? id,
    required String customerId,
    required int amount,
    required PaymentMethod method,
    String? refNote,
    String? billId,
    required String receivedByMemberId,
    bool enqueueRemote = true,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<int> totalDues() async => 0;
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  SyncingBillsRepository billsRepo() {
    final sync = SyncService(
      db: db,
      client: SupabaseClient('http://localhost', 'anon'),
      // Skip platform channels in pure unit tests.
      connectivityCheck: () async => const [ConnectivityResult.none],
      reachabilityProbe: () async => false,
    );
    return SyncingBillsRepository(
      db: db,
      sync: sync,
      payments: _FakePaymentsRepository(),
      businessId: 'biz',
    );
  }

  test('offline bill create decrements stockCached per line', () async {
    await db.ensureDeviceMeta('device-1');
    final now = DateTime.utc(2026, 7, 1);
    await db
        .into(db.localProducts)
        .insert(
          LocalProductsCompanion.insert(
            id: 'prod-a',
            businessId: 'biz',
            name: 'Cola',
            unit: 'piece',
            stockCached: const Value(10),
            updatedAt: now,
          ),
        );
    await db
        .into(db.localProducts)
        .insert(
          LocalProductsCompanion.insert(
            id: 'prod-b',
            businessId: 'biz',
            name: 'Chips',
            unit: 'piece',
            stockCached: const Value(3),
            updatedAt: now,
          ),
        );

    final repo = billsRepo();
    await repo.create(
      createdByMemberId: 'member-1',
      status: BillStatus.paid,
      itemsTotal: 1500,
      discount: 0,
      grandTotal: 1500,
      lines: const [
        BillLineInput(
          productId: 'prod-a',
          nameSnapshot: 'Cola',
          qty: 4,
          rate: 250,
          lineTotal: 1000,
        ),
        BillLineInput(
          productId: 'prod-b',
          nameSnapshot: 'Chips',
          qty: 2,
          rate: 250,
          lineTotal: 500,
        ),
      ],
    );

    final a = await (db.select(
      db.localProducts,
    )..where((p) => p.id.equals('prod-a'))).getSingle();
    final b = await (db.select(
      db.localProducts,
    )..where((p) => p.id.equals('prod-b'))).getSingle();
    expect(a.stockCached, 6);
    expect(b.stockCached, 1);
  });

  test('offline bill create allows negative stockCached', () async {
    await db.ensureDeviceMeta('device-1');
    await db
        .into(db.localProducts)
        .insert(
          LocalProductsCompanion.insert(
            id: 'prod-low',
            businessId: 'biz',
            name: 'Rare',
            unit: 'piece',
            stockCached: const Value(1),
            updatedAt: DateTime.utc(2026, 7, 1),
          ),
        );

    await billsRepo().create(
      createdByMemberId: 'member-1',
      status: BillStatus.paid,
      itemsTotal: 500,
      discount: 0,
      grandTotal: 500,
      lines: const [
        BillLineInput(
          productId: 'prod-low',
          nameSnapshot: 'Rare',
          qty: 5,
          rate: 100,
          lineTotal: 500,
        ),
      ],
    );

    final product = await (db.select(
      db.localProducts,
    )..where((p) => p.id.equals('prod-low'))).getSingle();
    expect(product.stockCached, -4);
  });

  test('manual amount sale skips stock decrement', () async {
    await db.ensureDeviceMeta('device-1');
    await db
        .into(db.localProducts)
        .insert(
          LocalProductsCompanion.insert(
            id: 'prod-x',
            businessId: 'biz',
            name: 'Widget',
            unit: 'piece',
            stockCached: const Value(8),
            updatedAt: DateTime.utc(2026, 7, 1),
          ),
        );
    await db
        .into(db.localCustomers)
        .insert(
          LocalCustomersCompanion.insert(
            id: 'cust-1',
            businessId: 'biz',
            memberId: 'm1',
            shopName: 'Shop',
            updatedAt: DateTime.utc(2026, 7, 1),
          ),
        );

    await billsRepo().recordAmountSale(
      customerId: 'cust-1',
      createdByMemberId: 'member-1',
      amountPaisa: 1000,
    );

    final product = await (db.select(
      db.localProducts,
    )..where((p) => p.id.equals('prod-x'))).getSingle();
    expect(product.stockCached, 8);
  });

  test('pruneSyncedQueue deletes old synced rows only', () async {
    final old = DateTime.now().toUtc().subtract(const Duration(days: 10));
    final recent = DateTime.now().toUtc().subtract(const Duration(days: 1));

    await db
        .into(db.syncQueue)
        .insert(
          SyncQueueCompanion.insert(
            entityType: 'bill',
            entityId: 'old-synced',
            payloadJson: '{}',
            status: const Value('synced'),
            createdAt: Value(old),
          ),
        );
    await db
        .into(db.syncQueue)
        .insert(
          SyncQueueCompanion.insert(
            entityType: 'bill',
            entityId: 'recent-synced',
            payloadJson: '{}',
            status: const Value('synced'),
            createdAt: Value(recent),
          ),
        );
    await db
        .into(db.syncQueue)
        .insert(
          SyncQueueCompanion.insert(
            entityType: 'bill',
            entityId: 'pending',
            payloadJson: '{}',
            status: const Value('pending'),
            createdAt: Value(old),
          ),
        );
    await db
        .into(db.syncQueue)
        .insert(
          SyncQueueCompanion.insert(
            entityType: 'bill',
            entityId: 'failed',
            payloadJson: '{}',
            status: const Value('failed'),
            createdAt: Value(old),
          ),
        );

    final deleted = await db.pruneSyncedQueue();
    expect(deleted, 1);

    final remaining = await db.select(db.syncQueue).get();
    expect(remaining.map((r) => r.entityId).toSet(), {
      'recent-synced',
      'pending',
      'failed',
    });
  });
}
