import 'package:freezed_annotation/freezed_annotation.dart';

part 'top_customer_row.freezed.dart';
part 'top_customer_row.g.dart';

@freezed
abstract class TopCustomerRow with _$TopCustomerRow {
  const factory TopCustomerRow({
    required String customerId,
    required String shopName,
    @Default(0) int billCount,
    @Default(0) int revenue,
  }) = _TopCustomerRow;

  factory TopCustomerRow.fromJson(Map<String, dynamic> json) =>
      _$TopCustomerRowFromJson(json);
}
