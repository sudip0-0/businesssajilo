import 'package:businesssajilo/data/local/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tenant switch wipes local data, watermarks, and queue', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());

    // Tenant A populates the cache.
    final wipedA = await db.prepareForBusiness('biz-a');
    expect(wipedA, isFalse);

    await db.into(db.localProducts).insert(
      LocalProductsCompanion.insert(
        id: 'prod-1',
        businessId: 'biz-a',
        name: 'Widget',
        unit: 'piece',
        updatedAt: DateTime.now().toUtc(),
      ),
    );
    await db.into(db.localBills).insert(
      LocalBillsCompanion.insert(
        id: 'bill-1',
        businessId: 'biz-a',
        billNo: 'D1-1',
        status: 'paid',
        createdBy: 'member-a',
      ),
    );
    await db.enqueue(
      entityType: 'bill',
      entityId: 'bill-1',
      payload: {'id': 'bill-1'},
    );
    await db.setWatermark('products', DateTime.now().toUtc());

    // Re-bootstrapping for the SAME tenant must keep everything.
    final wipedSame = await db.prepareForBusiness('biz-a');
    expect(wipedSame, isFalse);
    expect(await db.select(db.localProducts).get(), hasLength(1));
    expect(await db.pendingQueue(), hasLength(1));
    expect(await db.watermark('products'), isNotNull);

    // Switching tenant must wipe rows, queue, and watermarks.
    final wipedB = await db.prepareForBusiness('biz-b');
    expect(wipedB, isTrue);
    expect(await db.select(db.localProducts).get(), isEmpty);
    expect(await db.select(db.localBills).get(), isEmpty);
    expect(await db.pendingQueue(), isEmpty);
    expect(await db.watermark('products'), isNull);
    expect(await db.metaValue('business_id'), 'biz-b');

    await db.close();
  });
}
