import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/logging/app_log.dart';
import '../local/app_database.dart';
import '../remote/supabase_provider.dart';
import '../sync/sync_providers.dart';
import 'stock_repository.dart';

class StockCountLineInput {
  const StockCountLineInput({
    required this.productId,
    required this.countedQty,
    this.systemStock,
  });

  final String productId;
  final int countedQty;

  /// Optional snapshot of system stock used only for offline/fallback adjust delta.
  final int? systemStock;

  Map<String, dynamic> toRpcJson() => {
    'product_id': productId,
    'counted_qty': countedQty,
  };
}

class StockCountLineResult {
  const StockCountLineResult({
    required this.productId,
    required this.name,
    required this.previousStock,
    required this.countedQty,
    required this.delta,
    required this.newStock,
    this.movementId,
  });

  final String productId;
  final String name;
  final int previousStock;
  final int countedQty;
  final int delta;
  final int newStock;
  final String? movementId;

  factory StockCountLineResult.fromJson(Map<String, dynamic> json) {
    return StockCountLineResult(
      productId: json['product_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      previousStock: (json['previous_stock'] as num?)?.toInt() ?? 0,
      countedQty: (json['counted_qty'] as num?)?.toInt() ?? 0,
      delta: (json['delta'] as num?)?.toInt() ?? 0,
      newStock: (json['new_stock'] as num?)?.toInt() ?? 0,
      movementId: json['movement_id'] as String?,
    );
  }
}

class StockCountReconcileResult {
  const StockCountReconcileResult({
    required this.opId,
    required this.created,
    required this.reason,
    required this.totalItems,
    required this.adjustedCount,
    required this.unchangedCount,
    required this.items,
  });

  final String opId;
  final bool created;
  final String reason;
  final int totalItems;
  final int adjustedCount;
  final int unchangedCount;
  final List<StockCountLineResult> items;

  factory StockCountReconcileResult.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map(
                (e) =>
                    StockCountLineResult.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
        : const <StockCountLineResult>[];
    return StockCountReconcileResult(
      opId: json['op_id'] as String? ?? '',
      created: json['created'] != false,
      reason: json['reason'] as String? ?? '',
      totalItems: (json['total_items'] as num?)?.toInt() ?? items.length,
      adjustedCount: (json['adjusted_count'] as num?)?.toInt() ?? 0,
      unchangedCount: (json['unchanged_count'] as num?)?.toInt() ?? 0,
      items: items,
    );
  }
}

abstract class StockReconciliationRepository {
  Future<StockCountReconcileResult> reconcileStockCount({
    required String opId,
    required String reason,
    required List<StockCountLineInput> items,
    required String createdByMemberId,
  });
}

final stockReconciliationRepositoryProvider =
    Provider<StockReconciliationRepository>((ref) {
      final client = ref.watch(supabaseClientProvider);
      final stockRepo = ref.watch(stockRepositoryProvider);
      final bundle = ref.watch(syncBundleProvider);
      return SupabaseStockReconciliationRepository(
        client: client,
        fallbackStockRepo: stockRepo,
        localDb: bundle?.db,
      );
    });

class SupabaseStockReconciliationRepository
    implements StockReconciliationRepository {
  SupabaseStockReconciliationRepository({
    required SupabaseClient? client,
    required StockRepository fallbackStockRepo,
    AppDatabase? localDb,
  }) : _client = client,
       _fallbackStockRepo = fallbackStockRepo,
       _localDb = localDb;

  final SupabaseClient? _client;
  final StockRepository _fallbackStockRepo;
  final AppDatabase? _localDb;

  @override
  Future<StockCountReconcileResult> reconcileStockCount({
    required String opId,
    required String reason,
    required List<StockCountLineInput> items,
    required String createdByMemberId,
  }) async {
    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) {
      throw ArgumentError('Reason is required');
    }
    if (items.isEmpty) {
      throw ArgumentError('At least one product count is required');
    }

    final client = _client;
    if (client != null) {
      try {
        final raw = await client.rpc<dynamic>(
          'reconcile_stock_count',
          params: {
            'p': {
              'op_id': opId,
              'reason': trimmedReason,
              'items': items.map((e) => e.toRpcJson()).toList(),
            },
          },
        );
        if (raw is! Map) {
          throw StateError('Unexpected reconcile_stock_count response');
        }
        final result = StockCountReconcileResult.fromJson(
          Map<String, dynamic>.from(raw),
        );
        await _mirrorLocalStock(result);
        return result;
      } on PostgrestException catch (e) {
        // Only fall back when the RPC is not deployed on the server.
        // Never swallow permission, tenant, or retry-mismatch errors.
        if (e.code != 'PGRST202') rethrow;
        AppLog.warn('reconcile_stock_count RPC missing; using fallback', e);
      } catch (e, st) {
        // When offline on mobile staff (Drift sync bundle active), enqueue
        // append-only adjust movements locally instead of failing outright.
        if (_localDb == null) rethrow;
        AppLog.warn(
          'reconcile_stock_count online call failed; queueing offline adjustments',
          e,
          st,
        );
      }
    }

    return _fallbackAdjustments(
      opId: opId,
      reason: trimmedReason,
      items: items,
      createdByMemberId: createdByMemberId,
    );
  }

  Future<void> _mirrorLocalStock(StockCountReconcileResult result) async {
    final db = _localDb;
    if (db == null) return;
    await db.transaction(() async {
      for (final item in result.items) {
        await (db.update(db.localProducts)
              ..where((p) => p.id.equals(item.productId)))
            .write(LocalProductsCompanion(stockCached: Value(item.newStock)));
      }
    });
  }

  Future<StockCountReconcileResult> _fallbackAdjustments({
    required String opId,
    required String reason,
    required List<StockCountLineInput> items,
    required String createdByMemberId,
  }) async {
    final results = <StockCountLineResult>[];
    var adjusted = 0;
    var unchanged = 0;
    for (final item in items) {
      final prev = item.systemStock ?? 0;
      final delta = item.countedQty - prev;
      if (delta == 0) {
        unchanged++;
        results.add(
          StockCountLineResult(
            productId: item.productId,
            name: '',
            previousStock: prev,
            countedQty: item.countedQty,
            delta: 0,
            newStock: prev,
          ),
        );
        continue;
      }
      final movement = await _fallbackStockRepo.adjust(
        productId: item.productId,
        qtyDelta: delta,
        reason: reason,
        createdByMemberId: createdByMemberId,
      );
      adjusted++;
      results.add(
        StockCountLineResult(
          productId: item.productId,
          name: '',
          previousStock: prev,
          countedQty: item.countedQty,
          delta: delta,
          newStock: item.countedQty,
          movementId: movement.id,
        ),
      );
    }
    return StockCountReconcileResult(
      opId: opId,
      created: true,
      reason: reason,
      totalItems: items.length,
      adjustedCount: adjusted,
      unchangedCount: unchanged,
      items: results,
    );
  }
}
