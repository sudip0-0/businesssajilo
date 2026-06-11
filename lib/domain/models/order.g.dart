// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Order _$OrderFromJson(Map<String, dynamic> json) => _Order(
  id: json['id'] as String,
  businessId: json['business_id'] as String,
  customerId: json['customer_id'] as String,
  status: $enumDecode(_$OrderStatusEnumMap, json['status']),
  customerNote: json['customer_note'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
  customerShopName: json['customer_shop_name'] as String?,
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$OrderToJson(_Order instance) => <String, dynamic>{
  'id': instance.id,
  'business_id': instance.businessId,
  'customer_id': instance.customerId,
  'status': _$OrderStatusEnumMap[instance.status]!,
  'customer_note': instance.customerNote,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
  'customer_shop_name': instance.customerShopName,
  'items': instance.items.map((e) => e.toJson()).toList(),
};

const _$OrderStatusEnumMap = {
  OrderStatus.draft: 'draft',
  OrderStatus.placed: 'placed',
  OrderStatus.quoted: 'quoted',
  OrderStatus.accepted: 'accepted',
  OrderStatus.rejected: 'rejected',
  OrderStatus.confirmed: 'confirmed',
  OrderStatus.packed: 'packed',
  OrderStatus.dispatched: 'dispatched',
  OrderStatus.billed: 'billed',
  OrderStatus.closed: 'closed',
  OrderStatus.cancelled: 'cancelled',
};
