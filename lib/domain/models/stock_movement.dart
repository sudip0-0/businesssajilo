import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums.dart';

part 'stock_movement.freezed.dart';
part 'stock_movement.g.dart';

@freezed
abstract class StockMovement with _$StockMovement {
  const factory StockMovement({
    required String id,
    required String businessId,
    required String productId,
    required StockMovementType type,
    required int qtyDelta,
    String? reason,
    String? refOrderId,
    required String createdBy,
    DateTime? createdAt,
    String? createdByName,
  }) = _StockMovement;

  factory StockMovement.fromJson(Map<String, dynamic> json) =>
      _$StockMovementFromJson(json);
}
