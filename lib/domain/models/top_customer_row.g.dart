// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'top_customer_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TopCustomerRow _$TopCustomerRowFromJson(Map<String, dynamic> json) =>
    _TopCustomerRow(
      customerId: json['customer_id'] as String,
      shopName: json['shop_name'] as String,
      billCount: (json['bill_count'] as num?)?.toInt() ?? 0,
      revenue: (json['revenue'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$TopCustomerRowToJson(_TopCustomerRow instance) =>
    <String, dynamic>{
      'customer_id': instance.customerId,
      'shop_name': instance.shopName,
      'bill_count': instance.billCount,
      'revenue': instance.revenue,
    };
