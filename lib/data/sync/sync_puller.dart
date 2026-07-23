import 'package:supabase_flutter/supabase_flutter.dart';

import '../local/app_database.dart';
import 'sync_constants.dart';
import 'pull/sync_pull_entities.dart';
import 'pull/sync_pull_page.dart';

/// Orchestrates remote → local sync pulls (bootstrap + delta).
///
/// Delta ordering: categories/products → bills → payments → customers → stock.
/// Customer balances must run after bills/payments (financial timestamps).
///
/// Credit notes: server updates `customer_balances.updated_at`; delta pull on
/// the `customers` watermark picks up revised balance_due via Drift upsert.
class SyncPuller {
  SyncPuller({required AppDatabase db, required SupabaseClient client})
    : _db = db,
      _entities = SyncPullEntities(db: db, client: client);

  final AppDatabase _db;
  final SyncPullEntities _entities;

  /// True when bootstrap was interrupted by page/duration budget.
  bool bootstrapIncomplete = false;

  Future<void> pull() async {
    final now = DateTime.now().toUtc();
    final hasWatermarks = await _db
        .select(_db.syncWatermarks)
        .get()
        .then((r) => r.isNotEmpty);

    final bootstrapTable = await _db.metaValue(syncMetaBootstrapTable);
    if (!hasWatermarks || (bootstrapTable != null && bootstrapTable.isNotEmpty)) {
      bootstrapIncomplete = !await _bootstrapResumable();
    } else {
      bootstrapIncomplete = false;
      await _pullDelta();
    }

    if (!bootstrapIncomplete) {
      await _db.setWatermark('_global', now);
    }
  }

  Future<bool> _bootstrapResumable() async {
    final budget = SyncPullBudget();
    var startTable = await _db.metaValue(syncMetaBootstrapTable);
    var offset = int.tryParse(await _db.metaValue(syncMetaBootstrapOffset) ?? '') ?? 0;

    if (startTable != null && startTable.isEmpty) startTable = null;

    final startIndex = startTable == null
        ? 0
        : syncBootstrapTables.indexOf(startTable).clamp(0, syncBootstrapTables.length);

    for (var i = startIndex; i < syncBootstrapTables.length; i++) {
      final table = syncBootstrapTables[i];
      final tableOffset = i == startIndex ? offset : 0;
      final ts = DateTime.now().toUtc();

      final result = await _pullBootstrapTable(
        table,
        ts,
        startOffset: tableOffset,
        budget: budget,
      );

      if (result.outcome == PullPageOutcome.budgetExceeded) {
        await _db.setMetaValue(syncMetaBootstrapTable, table);
        await _db.setMetaValue(syncMetaBootstrapOffset, '${result.nextOffset}');
        return false;
      }

      offset = 0;
    }

    await _db.setMetaValue(syncMetaBootstrapTable, '');
    await _db.setMetaValue(syncMetaBootstrapOffset, '0');
    return true;
  }

  Future<PullPageResult> _pullBootstrapTable(
    String table,
    DateTime ts, {
    required int startOffset,
    required SyncPullBudget budget,
  }) {
    switch (table) {
      case 'categories':
        return _entities.pullCategoriesBootstrap(
          ts,
          startOffset: startOffset,
          budget: budget,
        );
      case 'products':
        return _entities.pullProductsBootstrap(
          ts,
          startOffset: startOffset,
          budget: budget,
        );
      case 'customers':
        return _entities.pullCustomerBalancesBootstrap(
          ts,
          startOffset: startOffset,
          budget: budget,
        );
      case 'bills':
        return _entities.pullBillsBootstrap(
          ts,
          startOffset: startOffset,
          budget: budget,
        );
      case 'payments':
        return _entities.pullPaymentsBootstrap(
          ts,
          startOffset: startOffset,
          budget: budget,
        );
      case 'stock_movements':
        return _entities.pullStockMovementsBootstrap(
          ts,
          startOffset: startOffset,
          budget: budget,
        );
      default:
        return Future.value(
          const PullPageResult(outcome: PullPageOutcome.complete, nextOffset: 0),
        );
    }
  }

  Future<void> _pullDelta() async {
    final catWatermark = await _db.watermark('categories');
    if (catWatermark != null) {
      await _entities.pullCategoriesDelta(
        catWatermark.toIso8601String(),
        DateTime.now().toUtc(),
      );
    }

    final prodWatermark = await _db.watermark('products');
    if (prodWatermark != null) {
      await _entities.pullProductsDelta(
        prodWatermark.toIso8601String(),
        DateTime.now().toUtc(),
      );
    }

    // Bills/payments first, then customers — balances.updated_at includes
    // financial activity timestamps (bills, payments, credit notes).
    final billWatermark = await _db.watermark('bills');
    if (billWatermark != null) {
      await _entities.pullBillsDelta(
        billWatermark.toIso8601String(),
        DateTime.now().toUtc(),
      );
    }

    final payWatermark = await _db.watermark('payments');
    if (payWatermark != null) {
      await _entities.pullPaymentsDelta(
        payWatermark.toIso8601String(),
        DateTime.now().toUtc(),
      );
    }

    final custWatermark = await _db.watermark('customers');
    if (custWatermark != null) {
      await _entities.pullCustomerBalancesDelta(
        custWatermark.toIso8601String(),
        DateTime.now().toUtc(),
      );
    }

    final movWatermark = await _db.watermark('stock_movements');
    if (movWatermark != null) {
      await _entities.pullStockMovementsDelta(
        movWatermark.toIso8601String(),
        DateTime.now().toUtc(),
      );
    }
  }
}
