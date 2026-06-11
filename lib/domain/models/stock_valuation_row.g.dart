// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_valuation_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StockValuationRow _$StockValuationRowFromJson(Map<String, dynamic> json) =>
    _StockValuationRow(
      productId: json['product_id'] as String,
      name: json['name'] as String,
      stockCached: (json['stock_cached'] as num?)?.toInt() ?? 0,
      costPrice: (json['cost_price'] as num?)?.toInt() ?? 0,
      valuation: (json['valuation'] as num?)?.toInt() ?? 0,
      isLowStock: json['is_low_stock'] as bool? ?? false,
    );

Map<String, dynamic> _$StockValuationRowToJson(_StockValuationRow instance) =>
    <String, dynamic>{
      'product_id': instance.productId,
      'name': instance.name,
      'stock_cached': instance.stockCached,
      'cost_price': instance.costPrice,
      'valuation': instance.valuation,
      'is_low_stock': instance.isLowStock,
    };
