// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profitable_customer_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProfitableCustomerRow _$ProfitableCustomerRowFromJson(
  Map<String, dynamic> json,
) => _ProfitableCustomerRow(
  customerId: json['customer_id'] as String,
  shopName: json['shop_name'] as String,
  billCount: (json['bill_count'] as num?)?.toInt() ?? 0,
  revenue: (json['revenue'] as num?)?.toInt() ?? 0,
  cogs: (json['cogs'] as num?)?.toInt() ?? 0,
  grossProfit: (json['gross_profit'] as num?)?.toInt() ?? 0,
  marginPct: (json['margin_pct'] as num?)?.toDouble() ?? 0.0,
);

Map<String, dynamic> _$ProfitableCustomerRowToJson(
  _ProfitableCustomerRow instance,
) => <String, dynamic>{
  'customer_id': instance.customerId,
  'shop_name': instance.shopName,
  'bill_count': instance.billCount,
  'revenue': instance.revenue,
  'cogs': instance.cogs,
  'gross_profit': instance.grossProfit,
  'margin_pct': instance.marginPct,
};
