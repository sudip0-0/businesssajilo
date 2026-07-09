import 'dart:async';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/enums.dart';
import '../../domain/models/stock_movement.dart';
import '../local/app_database.dart';
import '../local/local_mappers.dart';
import '../repositories/stock_repository.dart';
import 'sync_service.dart';

class SyncingStockRepository implements StockRepository {
  SyncingStockRepository({
    required AppDatabase db,
    required SyncService sync,
    required String businessId,
  })  : _db = db,
        _sync = sync,
        _businessId = businessId;

  final AppDatabase _db;
  final SyncService _sync;
  final String _businessId;
  static const _uuid = Uuid();

  @override
  Future<List<StockMovement>> listMovements(String productId) async {
    final rows = await (_db.select(_db.localStockMovements)
          ..where((m) => m.productId.equals(productId))
          ..orderBy([(m) => OrderingTerm.desc(m.createdAt)]))
        .get();
    return rows.map(mapLocalMovement).toList();
  }

  @override
  Future<StockMovement> stockIn({
    required String productId,
    required int qty,
    required String createdByMemberId,
  }) async {
    return _insertLocal(
      productId: productId,
      type: StockMovementType.stockIn,
      qtyDelta: qty,
      createdByMemberId: createdByMemberId,
    );
  }

  @override
  Future<StockMovement> adjust({
    required String productId,
    required int qtyDelta,
    required String reason,
    required String createdByMemberId,
  }) async {
    return _insertLocal(
      productId: productId,
      type: StockMovementType.adjust,
      qtyDelta: qtyDelta,
      reason: reason,
      createdByMemberId: createdByMemberId,
    );
  }

  Future<StockMovement> _insertLocal({
    required String productId,
    required StockMovementType type,
    required int qtyDelta,
    String? reason,
    required String createdByMemberId,
  }) async {
    final id = _uuid.v4();
    final typeDb = switch (type) {
      StockMovementType.stockIn => 'stock_in',
      StockMovementType.adjust => 'adjust',
      StockMovementType.dispatch => 'dispatch',
      StockMovementType.return_ => 'return',
    };

    await _db.into(_db.localStockMovements).insert(
      LocalStockMovementsCompanion.insert(
        id: id,
        businessId: _businessId,
        productId: productId,
        type: typeDb,
        qtyDelta: qtyDelta,
        reason: Value(reason),
        createdBy: createdByMemberId,
        syncStatus: const Value('pending'),
      ),
    );

    await (_db.update(_db.localProducts)..where((p) => p.id.equals(productId)))
        .write(
      LocalProductsCompanion(
        stockCached: Value(
          await _projectedStock(productId, qtyDelta),
        ),
      ),
    );

    await _db.enqueue(
      entityType: 'stock_movement',
      entityId: id,
      payload: {
        'id': id,
        'business_id': _businessId,
        'product_id': productId,
        'type': typeDb,
        'qty_delta': qtyDelta,
        'reason': reason,
        'created_by': createdByMemberId,
      },
    );

    unawaited(_sync.syncNow());
    return mapLocalMovement(
      await (_db.select(_db.localStockMovements)..where((m) => m.id.equals(id)))
          .getSingle(),
    );
  }

  Future<int> _projectedStock(String productId, int delta) async {
    final product = await (_db.select(_db.localProducts)
          ..where((p) => p.id.equals(productId)))
        .getSingle();
    return product.stockCached + delta;
  }
}
