import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../domain/enums.dart';
import '../../domain/models/stock_movement.dart';
import '../repositories/stock_repository.dart';
import 'supabase_provider.dart';

class SupabaseStockRepository implements StockRepository {
  SupabaseStockRepository(this._client);

  final SupabaseClient? _client;
  static const _uuid = Uuid();

  @override
  Future<List<StockMovement>> listMovements(String productId) async {
    final client = requireSupabaseClient(_client);
    final rows = await client
        .from('stock_movements')
        .select('*, members(display_name)')
        .eq('product_id', productId)
        .order('created_at', ascending: false);
    return (rows as List).map(_mapMovement).toList();
  }

  @override
  Future<StockMovement> stockIn({
    required String productId,
    required int qty,
    required String createdByMemberId,
  }) async {
    return _insert(
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
    return _insert(
      productId: productId,
      type: StockMovementType.adjust,
      qtyDelta: qtyDelta,
      reason: reason,
      createdByMemberId: createdByMemberId,
    );
  }

  Future<StockMovement> _insert({
    required String productId,
    required StockMovementType type,
    required int qtyDelta,
    String? reason,
    required String createdByMemberId,
  }) async {
    final client = requireSupabaseClient(_client);
    final product = await client
        .from('products')
        .select('business_id')
        .eq('id', productId)
        .single();
    final row = await client
        .from('stock_movements')
        .insert({
          'id': _uuid.v4(),
          'business_id': product['business_id'],
          'product_id': productId,
          'type': _typeToDb(type),
          'qty_delta': qtyDelta,
          'reason': ?reason,
          'created_by': createdByMemberId,
        })
        .select('*, members(display_name)')
        .single();
    return _mapMovement(row);
  }

  String _typeToDb(StockMovementType type) => switch (type) {
    StockMovementType.stockIn => 'stock_in',
    StockMovementType.adjust => 'adjust',
    StockMovementType.dispatch => 'dispatch',
    StockMovementType.return_ => 'return',
  };

  StockMovement _mapMovement(dynamic row) {
    final map = Map<String, dynamic>.from(row as Map);
    final member = map.remove('members');
    if (member is Map) {
      map['created_by_name'] = member['display_name'];
    }
    return StockMovement.fromJson(map);
  }
}
