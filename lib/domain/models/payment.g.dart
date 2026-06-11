// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Payment _$PaymentFromJson(Map<String, dynamic> json) => _Payment(
  id: json['id'] as String,
  businessId: json['business_id'] as String,
  customerId: json['customer_id'] as String,
  billId: json['bill_id'] as String?,
  amount: (json['amount'] as num).toInt(),
  method: $enumDecode(_$PaymentMethodEnumMap, json['method']),
  refNote: json['ref_note'] as String?,
  receivedBy: json['received_by'] as String,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$PaymentToJson(_Payment instance) => <String, dynamic>{
  'id': instance.id,
  'business_id': instance.businessId,
  'customer_id': instance.customerId,
  'bill_id': instance.billId,
  'amount': instance.amount,
  'method': _$PaymentMethodEnumMap[instance.method]!,
  'ref_note': instance.refNote,
  'received_by': instance.receivedBy,
  'created_at': instance.createdAt?.toIso8601String(),
};

const _$PaymentMethodEnumMap = {
  PaymentMethod.cash: 'cash',
  PaymentMethod.cheque: 'cheque',
  PaymentMethod.wallet: 'wallet',
  PaymentMethod.bank: 'bank',
};
