// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'top_product_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TopProductRow _$TopProductRowFromJson(Map<String, dynamic> json) =>
    _TopProductRow(
      productId: json['product_id'] as String,
      nameSnapshot: json['name_snapshot'] as String,
      qtySold: (json['qty_sold'] as num?)?.toInt() ?? 0,
      revenue: (json['revenue'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$TopProductRowToJson(_TopProductRow instance) =>
    <String, dynamic>{
      'product_id': instance.productId,
      'name_snapshot': instance.nameSnapshot,
      'qty_sold': instance.qtySold,
      'revenue': instance.revenue,
    };
