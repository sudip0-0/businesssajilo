// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profitable_product_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProfitableProductRow _$ProfitableProductRowFromJson(
  Map<String, dynamic> json,
) => _ProfitableProductRow(
  productId: json['product_id'] as String,
  nameSnapshot: json['name_snapshot'] as String,
  qtySold: (json['qty_sold'] as num?)?.toInt() ?? 0,
  revenue: (json['revenue'] as num?)?.toInt() ?? 0,
  cogs: (json['cogs'] as num?)?.toInt() ?? 0,
  grossProfit: (json['gross_profit'] as num?)?.toInt() ?? 0,
  marginPct: (json['margin_pct'] as num?)?.toDouble() ?? 0.0,
);

Map<String, dynamic> _$ProfitableProductRowToJson(
  _ProfitableProductRow instance,
) => <String, dynamic>{
  'product_id': instance.productId,
  'name_snapshot': instance.nameSnapshot,
  'qty_sold': instance.qtySold,
  'revenue': instance.revenue,
  'cogs': instance.cogs,
  'gross_profit': instance.grossProfit,
  'margin_pct': instance.marginPct,
};
