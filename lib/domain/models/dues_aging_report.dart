import 'package:freezed_annotation/freezed_annotation.dart';

import 'aging_customer_row.dart';

part 'dues_aging_report.freezed.dart';
part 'dues_aging_report.g.dart';

@freezed
abstract class DuesAgingReport with _$DuesAgingReport {
  const factory DuesAgingReport({
    @Default(0) int bucket0to30,
    @Default(0) int bucket31to60,
    @Default(0) int bucket60plus,
    @Default([]) List<AgingCustomerRow> customers,
  }) = _DuesAgingReport;

  factory DuesAgingReport.fromJson(Map<String, dynamic> json) =>
      _$DuesAgingReportFromJson(json);
}
