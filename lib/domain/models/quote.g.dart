// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quote.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Quote _$QuoteFromJson(Map<String, dynamic> json) => _Quote(
  id: json['id'] as String,
  orderId: json['order_id'] as String,
  version: (json['version'] as num).toInt(),
  status: $enumDecode(_$QuoteStatusEnumMap, json['status']),
  total: (json['total'] as num?)?.toInt() ?? 0,
  responseComment: json['response_comment'] as String?,
  createdBy: json['created_by'] as String,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => QuoteItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$QuoteToJson(_Quote instance) => <String, dynamic>{
  'id': instance.id,
  'order_id': instance.orderId,
  'version': instance.version,
  'status': _$QuoteStatusEnumMap[instance.status]!,
  'total': instance.total,
  'response_comment': instance.responseComment,
  'created_by': instance.createdBy,
  'created_at': instance.createdAt?.toIso8601String(),
  'items': instance.items.map((e) => e.toJson()).toList(),
};

const _$QuoteStatusEnumMap = {
  QuoteStatus.sent: 'sent',
  QuoteStatus.accepted: 'accepted',
  QuoteStatus.rejected: 'rejected',
};
