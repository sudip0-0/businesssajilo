// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Message _$MessageFromJson(Map<String, dynamic> json) => _Message(
  id: json['id'] as String,
  orderId: json['order_id'] as String,
  businessId: json['business_id'] as String,
  senderMemberId: json['sender_member_id'] as String,
  body: json['body'] as String? ?? '',
  imageUrl: json['image_url'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  senderName: json['sender_name'] as String?,
);

Map<String, dynamic> _$MessageToJson(_Message instance) => <String, dynamic>{
  'id': instance.id,
  'order_id': instance.orderId,
  'business_id': instance.businessId,
  'sender_member_id': instance.senderMemberId,
  'body': instance.body,
  'image_url': instance.imageUrl,
  'created_at': instance.createdAt?.toIso8601String(),
  'sender_name': instance.senderName,
};
