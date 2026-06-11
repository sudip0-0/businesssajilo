// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Customer _$CustomerFromJson(Map<String, dynamic> json) => _Customer(
  id: json['id'] as String,
  businessId: json['business_id'] as String,
  memberId: json['member_id'] as String,
  shopName: json['shop_name'] as String,
  contactName: json['contact_name'] as String?,
  phone: json['phone'] as String?,
  address: json['address'] as String?,
  openingBalance: (json['opening_balance'] as num?)?.toInt() ?? 0,
  balanceDue: (json['balance_due'] as num?)?.toInt() ?? 0,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$CustomerToJson(_Customer instance) => <String, dynamic>{
  'id': instance.id,
  'business_id': instance.businessId,
  'member_id': instance.memberId,
  'shop_name': instance.shopName,
  'contact_name': instance.contactName,
  'phone': instance.phone,
  'address': instance.address,
  'opening_balance': instance.openingBalance,
  'balance_due': instance.balanceDue,
  'created_at': instance.createdAt?.toIso8601String(),
};
