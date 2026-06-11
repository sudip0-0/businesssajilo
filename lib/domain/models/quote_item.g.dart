// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quote_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_QuoteItem _$QuoteItemFromJson(Map<String, dynamic> json) => _QuoteItem(
  id: json['id'] as String,
  quoteId: json['quote_id'] as String,
  productId: json['product_id'] as String,
  qty: (json['qty'] as num).toInt(),
  rate: (json['rate'] as num?)?.toInt() ?? 0,
  discount: (json['discount'] as num?)?.toInt() ?? 0,
  lineTotal: (json['line_total'] as num?)?.toInt() ?? 0,
  productName: json['product_name'] as String?,
);

Map<String, dynamic> _$QuoteItemToJson(_QuoteItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'quote_id': instance.quoteId,
      'product_id': instance.productId,
      'qty': instance.qty,
      'rate': instance.rate,
      'discount': instance.discount,
      'line_total': instance.lineTotal,
      'product_name': instance.productName,
    };
