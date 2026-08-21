import 'package:freezed_annotation/freezed_annotation.dart';

part 'profitable_customer_row.freezed.dart';
part 'profitable_customer_row.g.dart';

@freezed
abstract class ProfitableCustomerRow with _$ProfitableCustomerRow {
  const factory ProfitableCustomerRow({
    @JsonKey(name: 'customer_id') required String customerId,
    @JsonKey(name: 'shop_name') required String shopName,
    @JsonKey(name: 'bill_count') @Default(0) int billCount,
    @Default(0) int revenue,
    @Default(0) int cogs,
    @JsonKey(name: 'gross_profit') @Default(0) int grossProfit,
    @JsonKey(name: 'margin_pct') @Default(0.0) double marginPct,
  }) = _ProfitableCustomerRow;

  factory ProfitableCustomerRow.fromJson(Map<String, dynamic> json) =>
      _$ProfitableCustomerRowFromJson(json);
}
