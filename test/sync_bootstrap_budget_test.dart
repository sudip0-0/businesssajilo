import 'package:businesssajilo/data/local/app_database.dart';
import 'package:businesssajilo/data/sync/pull/sync_pull_page.dart';
import 'package:businesssajilo/data/sync/sync_constants.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bootstrap budget stops mid-table and preserves offset', () async {
    final budget = SyncPullBudget(maxPages: 2);
    final page = const SyncPullPage();

    var callCount = 0;
    final result = await page.pullPaged(
      entityLabel: 'products',
      startOffset: 0,
      budget: budget,
      pageSize: 2,
      buildPage: (from, to) async {
        callCount++;
        return [
          {'id': 'row-$from'},
          {'id': 'row-${from + 1}'},
        ];
      },
      onPage: (_) async {},
    );

    expect(result.outcome, PullPageOutcome.budgetExceeded);
    expect(result.nextOffset, 4);
    expect(callCount, 2);
  });

  test('watermark not set when bootstrap table incomplete', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await db.setMetaValue(syncMetaBootstrapTable, 'categories');
    await db.setMetaValue(syncMetaBootstrapOffset, '500');

    expect(await db.watermark('categories'), isNull);
    expect(await db.metaValue(syncMetaBootstrapTable), 'categories');
    expect(await db.metaValue(syncMetaBootstrapOffset), '500');
  });

  test('watermark set only after table completes', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await db.setWatermark('categories', DateTime.utc(2026, 1, 1));
    expect(await db.watermark('categories'), isNotNull);

    await db.setMetaValue(syncMetaBootstrapTable, 'products');
    expect(await db.watermark('products'), isNull);
  });
}
