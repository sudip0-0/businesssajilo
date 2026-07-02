// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Member _$MemberFromJson(Map<String, dynamic> json) => _Member(
  id: json['id'] as String,
  businessId: json['business_id'] as String,
  authUserId: json['auth_user_id'] as String,
  role: $enumDecode(_$RoleEnumMap, json['role']),
  displayName: json['display_name'] as String,
  phone: json['phone'] as String?,
  isActive: json['is_active'] as bool? ?? true,
  mustChangePassword: json['must_change_password'] as bool? ?? false,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$MemberToJson(_Member instance) => <String, dynamic>{
  'id': instance.id,
  'business_id': instance.businessId,
  'auth_user_id': instance.authUserId,
  'role': _$RoleEnumMap[instance.role]!,
  'display_name': instance.displayName,
  'phone': instance.phone,
  'is_active': instance.isActive,
  'must_change_password': instance.mustChangePassword,
  'created_at': instance.createdAt?.toIso8601String(),
};

const _$RoleEnumMap = {
  Role.owner: 'owner',
  Role.sales: 'sales',
  Role.warehouse: 'warehouse',
  Role.customer: 'customer',
};
