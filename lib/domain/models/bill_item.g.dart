// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bill_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BillItem _$BillItemFromJson(Map<String, dynamic> json) => _BillItem(
  id: json['id'] as String,
  billId: json['bill_id'] as String,
  productId: json['product_id'] as String,
  nameSnapshot: json['name_snapshot'] as String,
  qty: (json['qty'] as num).toInt(),
  rate: (json['rate'] as num?)?.toInt() ?? 0,
  discount: (json['discount'] as num?)?.toInt() ?? 0,
  lineTotal: (json['line_total'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$BillItemToJson(_BillItem instance) => <String, dynamic>{
  'id': instance.id,
  'bill_id': instance.billId,
  'product_id': instance.productId,
  'name_snapshot': instance.nameSnapshot,
  'qty': instance.qty,
  'rate': instance.rate,
  'discount': instance.discount,
  'line_total': instance.lineTotal,
};
