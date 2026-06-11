// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sales_period_point.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SalesPeriodPoint _$SalesPeriodPointFromJson(Map<String, dynamic> json) =>
    _SalesPeriodPoint(
      saleDate: DateTime.parse(json['sale_date'] as String),
      billCount: (json['bill_count'] as num?)?.toInt() ?? 0,
      totalSales: (json['total_sales'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$SalesPeriodPointToJson(_SalesPeriodPoint instance) =>
    <String, dynamic>{
      'sale_date': instance.saleDate.toIso8601String(),
      'bill_count': instance.billCount,
      'total_sales': instance.totalSales,
    };
