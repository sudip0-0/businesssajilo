// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'business.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Business _$BusinessFromJson(Map<String, dynamic> json) => _Business(
  id: json['id'] as String,
  name: json['name'] as String,
  nameNp: json['name_np'] as String?,
  address: json['address'] as String?,
  phone: json['phone'] as String?,
  logoUrl: json['logo_url'] as String?,
  subscriptionPlan: json['subscription_plan'] as String? ?? 'free',
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$BusinessToJson(_Business instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'name_np': instance.nameNp,
  'address': instance.address,
  'phone': instance.phone,
  'logo_url': instance.logoUrl,
  'subscription_plan': instance.subscriptionPlan,
  'created_at': instance.createdAt?.toIso8601String(),
};
