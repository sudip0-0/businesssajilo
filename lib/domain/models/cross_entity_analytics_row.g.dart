// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cross_entity_analytics_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CrossEntityAnalyticsRow _$CrossEntityAnalyticsRowFromJson(
  Map<String, dynamic> json,
) => _CrossEntityAnalyticsRow(
  id: json['id'] as String,
  label: json['label'] as String,
  qtySold: (json['qty_sold'] as num?)?.toInt() ?? 0,
  revenue: (json['revenue'] as num?)?.toInt() ?? 0,
  grossProfit: (json['gross_profit'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$CrossEntityAnalyticsRowToJson(
  _CrossEntityAnalyticsRow instance,
) => <String, dynamic>{
  'id': instance.id,
  'label': instance.label,
  'qty_sold': instance.qtySold,
  'revenue': instance.revenue,
  'gross_profit': instance.grossProfit,
};
