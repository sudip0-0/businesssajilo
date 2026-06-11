import 'package:freezed_annotation/freezed_annotation.dart';

part 'aging_customer_row.freezed.dart';
part 'aging_customer_row.g.dart';

@freezed
abstract class AgingCustomerRow with _$AgingCustomerRow {
  const factory AgingCustomerRow({
    required String customerId,
    required String shopName,
    @Default(0) int balanceDue,
    required DateTime oldestDueAt,
    @Default(0) int ageDays,
    required String bucket,
  }) = _AgingCustomerRow;

  factory AgingCustomerRow.fromJson(Map<String, dynamic> json) =>
      _$AgingCustomerRowFromJson(json);
}
