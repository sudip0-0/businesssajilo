import 'package:businesssajilo/data/local/app_database.dart';
import 'package:businesssajilo/data/sync/sync_merge.dart';
import 'package:businesssajilo/data/sync/sync_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('multi-device offline scenarios', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('concurrent offline bills decrement shared product stock', () async {
      await db.ensureDeviceMeta('device-a');
      final now = DateTime.utc(2026, 7, 1);
      await db.into(db.localProducts).insert(
            LocalProductsCompanion.insert(
              id: 'shared-prod',
              businessId: 'biz',
              name: 'Shared',
              unit: 'piece',
              stockCached: const Value(20),
              updatedAt: now,
            ),
          );

      for (var i = 0; i < 2; i++) {
        final billId = 'bill-$i';
        await db.into(db.localBills).insert(
              LocalBillsCompanion.insert(
                id: billId,
                businessId: 'biz',
                billNo: 'D1-$i',
                status: 'paid',
                createdBy: 'member-1',
                syncStatus: const Value('pending'),
              ),
            );
        await db.enqueue(
          entityType: 'bill',
          entityId: billId,
          payload: {'id': billId, 'lines': []},
        );
        await (db.update(db.localProducts)
              ..where((p) => p.id.equals('shared-prod')))
            .write(
          LocalProductsCompanion(
            stockCached: Value(20 - ((i + 1) * 3)),
          ),
        );
      }

      final product = await (db.select(db.localProducts)
            ..where((p) => p.id.equals('shared-prod')))
          .getSingle();
      expect(product.stockCached, 14);
      expect(await db.pendingQueue(), hasLength(2));
    });

    test('queue dependency ordering keeps bill before payment', () async {
      const billId = 'bill-dep';
      await db.enqueue(
        entityType: 'bill',
        entityId: billId,
        payload: {'id': billId},
      );
      await db.enqueue(
        entityType: 'payment',
        entityId: 'pay-dep',
        dependsOnId: billId,
        payload: {'id': 'pay-dep', 'bill_id': billId},
      );

      final queue = await db.pendingQueue();
      expect(queue.first.entityType, 'bill');
      expect(queue.last.dependsOnId, billId);
    });

    test('tenant switch clears queue and watermarks', () async {
      await db.prepareForBusiness('tenant-a');
      await db.setWatermark('products', DateTime.utc(2026, 1, 1));
      await db.enqueue(
        entityType: 'bill',
        entityId: 'b1',
        payload: {'id': 'b1'},
      );

      await db.prepareForBusiness('tenant-b');

      expect(await db.pendingQueue(), isEmpty);
      expect(await db.watermark('products'), isNull);
      expect(await db.metaValue('business_id'), 'tenant-b');
    });

    test('last-write-wins keeps newer remote product updated_at', () {
      final local = DateTime.utc(2026, 3, 1);
      final remote = DateTime.utc(2026, 6, 1);
      expect(remoteWins(local, remote), isTrue);
      expect(remoteWins(remote, local), isFalse);
      expect(pickNewerUpdatedAt(local, remote), remote);
    });
  });

  test('push returns zero when queue is empty', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final sync = SyncService(
      db: db,
      client: SupabaseClient('http://localhost', 'anon'),
      connectivityCheck: () async => [ConnectivityResult.none],
      reachabilityProbe: () async => false,
    );

    await db.ensureDeviceMeta('dev-1');
    await sync.syncNow();
    expect(await db.pendingQueue(), isEmpty);
  });
}
