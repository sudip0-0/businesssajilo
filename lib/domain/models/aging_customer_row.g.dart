// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'aging_customer_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AgingCustomerRow _$AgingCustomerRowFromJson(Map<String, dynamic> json) =>
    _AgingCustomerRow(
      customerId: json['customer_id'] as String,
      shopName: json['shop_name'] as String,
      balanceDue: (json['balance_due'] as num?)?.toInt() ?? 0,
      oldestDueAt: DateTime.parse(json['oldest_due_at'] as String),
      ageDays: (json['age_days'] as num?)?.toInt() ?? 0,
      bucket: json['bucket'] as String,
    );

Map<String, dynamic> _$AgingCustomerRowToJson(_AgingCustomerRow instance) =>
    <String, dynamic>{
      'customer_id': instance.customerId,
      'shop_name': instance.shopName,
      'balance_due': instance.balanceDue,
      'oldest_due_at': instance.oldestDueAt.toIso8601String(),
      'age_days': instance.ageDays,
      'bucket': instance.bucket,
    };
