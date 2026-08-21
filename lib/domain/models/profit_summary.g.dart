// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profit_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProfitSummary _$ProfitSummaryFromJson(Map<String, dynamic> json) =>
    _ProfitSummary(
      totalRevenue: (json['total_revenue'] as num?)?.toInt() ?? 0,
      totalCogs: (json['total_cogs'] as num?)?.toInt() ?? 0,
      grossProfit: (json['gross_profit'] as num?)?.toInt() ?? 0,
      marginPct: (json['margin_pct'] as num?)?.toDouble() ?? 0.0,
      totalBills: (json['total_bills'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ProfitSummaryToJson(_ProfitSummary instance) =>
    <String, dynamic>{
      'total_revenue': instance.totalRevenue,
      'total_cogs': instance.totalCogs,
      'gross_profit': instance.grossProfit,
      'margin_pct': instance.marginPct,
      'total_bills': instance.totalBills,
    };
