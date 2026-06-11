// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ledger_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LedgerEntry _$LedgerEntryFromJson(Map<String, dynamic> json) => _LedgerEntry(
  customerId: json['customer_id'] as String,
  businessId: json['business_id'] as String,
  occurredAt: DateTime.parse(json['occurred_at'] as String),
  entryType: json['entry_type'] as String,
  description: json['description'] as String,
  debitPaisa: (json['debit_paisa'] as num?)?.toInt() ?? 0,
  creditPaisa: (json['credit_paisa'] as num?)?.toInt() ?? 0,
  refId: json['ref_id'] as String?,
  runningBalance: (json['running_balance'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$LedgerEntryToJson(_LedgerEntry instance) =>
    <String, dynamic>{
      'customer_id': instance.customerId,
      'business_id': instance.businessId,
      'occurred_at': instance.occurredAt.toIso8601String(),
      'entry_type': instance.entryType,
      'description': instance.description,
      'debit_paisa': instance.debitPaisa,
      'credit_paisa': instance.creditPaisa,
      'ref_id': instance.refId,
      'running_balance': instance.runningBalance,
    };
