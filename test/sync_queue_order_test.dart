import 'dart:convert';

import 'package:businesssajilo/data/local/app_database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('timestamp ties use queue row id in all queue views', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    for (final id in ['z', 'a', 'm']) {
      await db.enqueue(entityType: 'bill', entityId: id, payload: {'id': id});
    }
    await db
        .update(db.syncQueue)
        .write(SyncQueueCompanion(createdAt: Value(DateTime.utc(2026))));
    expect((await db.pendingQueue()).map((q) => q.entityId), ['z', 'a', 'm']);
    expect((await db.unsyncedQueue()).map((q) => q.entityId), ['z', 'a', 'm']);
    expect((await db.watchUnsyncedQueue().first).map((q) => q.entityId), [
      'z',
      'a',
      'm',
    ]);
  });

  test('enqueue preserves bill before dependent rows', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    const billId = 'bill-1';

    await db.enqueue(
      entityType: 'bill',
      entityId: billId,
      payload: {'id': billId},
    );
    await db.enqueue(
      entityType: 'bill_items',
      entityId: billId,
      dependsOnId: billId,
      payload: {'items': []},
    );
    await db.enqueue(
      entityType: 'payment',
      entityId: 'pay-1',
      dependsOnId: billId,
      payload: {'id': 'pay-1', 'bill_id': billId},
    );

    final queue = await db.pendingQueue();
    expect(queue, hasLength(3));
    expect(queue[0].entityType, 'bill');
    expect(queue[1].entityType, 'bill_items');
    expect(queue[1].dependsOnId, billId);
    expect(queue[2].entityType, 'payment');
    expect(
      jsonDecode(queue[2].payloadJson) as Map<String, dynamic>,
      containsPair('bill_id', billId),
    );
    await db.close();
  });
}
