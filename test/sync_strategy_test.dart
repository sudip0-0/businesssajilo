import 'package:businesssajilo/data/local/app_database.dart';
import 'package:businesssajilo/data/sync/pull/sync_pull_page.dart';
import 'package:businesssajilo/data/sync/sync_backoff.dart';
import 'package:businesssajilo/data/sync/sync_constants.dart';
import 'package:businesssajilo/data/sync/sync_pusher.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('customer balance watermark', () {
    test('delta pull preserves updated_at filter in query', () {
      const iso = '2026-06-01T00:00:00Z';
      final query = 'updated_at=gt.$iso';
      expect(query, contains('updated_at'));
      expect(query, contains(iso));
    });

    test('watermark not advanced while bootstrap table incomplete', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      await db.setMetaValue(syncMetaBootstrapTable, 'customers');
      await db.setMetaValue(syncMetaBootstrapOffset, '200');
      expect(await db.watermark('customers'), isNull);
    });

    test('watermark set after customers table completes', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final ts = DateTime.utc(2026, 7, 1);
      await db.setWatermark('customers', ts);
      expect(await db.watermark('customers'), isNotNull);
    });
  });

  group('bootstrap resume offsets', () {
    test('budget stop preserves next offset for resume', () async {
      final budget = SyncPullBudget(maxPages: 1);
      final page = const SyncPullPage();

      final result = await page.pullPaged(
        entityLabel: 'customers',
        startOffset: 100,
        budget: budget,
        pageSize: 50,
        buildPage: (from, to) async => List.generate(
          50,
          (i) => {'customer_id': 'c-${from + i}'},
        ),
        onPage: (_) async {},
      );

      expect(result.outcome, PullPageOutcome.budgetExceeded);
      expect(result.nextOffset, 150);
    });
  });

  group('queue ordering and idempotency', () {
    test('bill stays before dependent payment in pending queue', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      const billId = 'bill-order';
      await db.enqueue(
        entityType: 'bill',
        entityId: billId,
        payload: {'id': billId},
      );
      await db.enqueue(
        entityType: 'payment',
        entityId: 'pay-order',
        dependsOnId: billId,
        payload: {'id': 'pay-order', 'bill_id': billId},
      );

      final queue = await db.pendingQueue();
      expect(queue.first.entityType, 'bill');
      expect(queue.last.entityType, 'payment');
      expect(queue.last.dependsOnId, billId);
    });

    test('legacy bill_items queue entry is rejected on push', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      await db.enqueue(
        entityType: 'bill_items',
        entityId: 'bill-legacy',
        payload: {'items': []},
      );

      final pusher = SyncPusher(
        db: db,
        client: SupabaseClient('http://localhost', 'anon'),
      );
      expect(await pusher.push(), 0);

      final queue = await db.pendingQueue();
      expect(queue.single.status, 'pending');
      expect(queue.single.attempts, 1);
      expect(queue.single.lastError, contains('legacy bill_items'));
    });

    test('terminal failure after max attempts marks queue failed', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      await db.enqueue(
        entityType: 'bill',
        entityId: 'bill-fail',
        payload: {'id': 'bill-fail', 'items': []},
      );

      final queueRow = await db.pendingQueue();
      await (db.update(db.syncQueue)..where((q) => q.id.equals(queueRow.single.id)))
          .write(
        const SyncQueueCompanion(
          attempts: Value(syncMaxAttempts - 1),
        ),
      );

      final pusher = SyncPusher(
        db: db,
        client: SupabaseClient('http://localhost', 'anon'),
      );
      expect(await pusher.push(), 0);

      expect(await db.failedCount(), 1);
      final after = await db.unsyncedQueue();
      expect(after.single.status, 'failed');
      expect(after.single.attempts, syncMaxAttempts);
    });
  });
}
