// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_movement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StockMovement _$StockMovementFromJson(Map<String, dynamic> json) =>
    _StockMovement(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      productId: json['product_id'] as String,
      type: $enumDecode(_$StockMovementTypeEnumMap, json['type']),
      qtyDelta: (json['qty_delta'] as num).toInt(),
      reason: json['reason'] as String?,
      refOrderId: json['ref_order_id'] as String?,
      createdBy: json['created_by'] as String,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      createdByName: json['created_by_name'] as String?,
    );

Map<String, dynamic> _$StockMovementToJson(_StockMovement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'business_id': instance.businessId,
      'product_id': instance.productId,
      'type': _$StockMovementTypeEnumMap[instance.type]!,
      'qty_delta': instance.qtyDelta,
      'reason': instance.reason,
      'ref_order_id': instance.refOrderId,
      'created_by': instance.createdBy,
      'created_at': instance.createdAt?.toIso8601String(),
      'created_by_name': instance.createdByName,
    };

const _$StockMovementTypeEnumMap = {
  StockMovementType.stockIn: 'stock_in',
  StockMovementType.adjust: 'adjust',
  StockMovementType.dispatch: 'dispatch',
  StockMovementType.return_: 'return',
};
