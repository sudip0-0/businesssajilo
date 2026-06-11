// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bill.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Bill _$BillFromJson(Map<String, dynamic> json) => _Bill(
  id: json['id'] as String,
  businessId: json['business_id'] as String,
  customerId: json['customer_id'] as String?,
  orderId: json['order_id'] as String?,
  billNo: json['bill_no'] as String,
  devicePrefix: json['device_prefix'] as String?,
  itemsTotal: (json['items_total'] as num?)?.toInt() ?? 0,
  discount: (json['discount'] as num?)?.toInt() ?? 0,
  grandTotal: (json['grand_total'] as num?)?.toInt() ?? 0,
  status: $enumDecode(_$BillStatusEnumMap, json['status']),
  createdBy: json['created_by'] as String,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  customerShopName: json['customer_shop_name'] as String?,
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => BillItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  pendingSync: json['pending_sync'] as bool? ?? false,
);

Map<String, dynamic> _$BillToJson(_Bill instance) => <String, dynamic>{
  'id': instance.id,
  'business_id': instance.businessId,
  'customer_id': instance.customerId,
  'order_id': instance.orderId,
  'bill_no': instance.billNo,
  'device_prefix': instance.devicePrefix,
  'items_total': instance.itemsTotal,
  'discount': instance.discount,
  'grand_total': instance.grandTotal,
  'status': _$BillStatusEnumMap[instance.status]!,
  'created_by': instance.createdBy,
  'created_at': instance.createdAt?.toIso8601String(),
  'customer_shop_name': instance.customerShopName,
  'items': instance.items.map((e) => e.toJson()).toList(),
  'pending_sync': instance.pendingSync,
};

const _$BillStatusEnumMap = {
  BillStatus.paid: 'paid',
  BillStatus.partial: 'partial',
  BillStatus.due: 'due',
};
