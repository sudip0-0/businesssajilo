// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OrderItem _$OrderItemFromJson(Map<String, dynamic> json) => _OrderItem(
  id: json['id'] as String,
  orderId: json['order_id'] as String,
  productId: json['product_id'] as String,
  qty: (json['qty'] as num).toInt(),
  productName: json['product_name'] as String?,
  productNameNp: json['product_name_np'] as String?,
  unit: json['unit'] as String?,
  imageUrl: json['image_url'] as String?,
);

Map<String, dynamic> _$OrderItemToJson(_OrderItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'order_id': instance.orderId,
      'product_id': instance.productId,
      'qty': instance.qty,
      'product_name': instance.productName,
      'product_name_np': instance.productNameNp,
      'unit': instance.unit,
      'image_url': instance.imageUrl,
    };
