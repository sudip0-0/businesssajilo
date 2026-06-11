// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dues_aging_report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DuesAgingReport _$DuesAgingReportFromJson(Map<String, dynamic> json) =>
    _DuesAgingReport(
      bucket0to30: (json['bucket0to30'] as num?)?.toInt() ?? 0,
      bucket31to60: (json['bucket31to60'] as num?)?.toInt() ?? 0,
      bucket60plus: (json['bucket60plus'] as num?)?.toInt() ?? 0,
      customers:
          (json['customers'] as List<dynamic>?)
              ?.map((e) => AgingCustomerRow.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$DuesAgingReportToJson(_DuesAgingReport instance) =>
    <String, dynamic>{
      'bucket0to30': instance.bucket0to30,
      'bucket31to60': instance.bucket31to60,
      'bucket60plus': instance.bucket60plus,
      'customers': instance.customers.map((e) => e.toJson()).toList(),
    };
