import 'package:freezed_annotation/freezed_annotation.dart';

part 'profit_summary.freezed.dart';
part 'profit_summary.g.dart';

@freezed
abstract class ProfitSummary with _$ProfitSummary {
  const factory ProfitSummary({
    @JsonKey(name: 'total_revenue') @Default(0) int totalRevenue,
    @JsonKey(name: 'total_cogs') @Default(0) int totalCogs,
    @JsonKey(name: 'gross_profit') @Default(0) int grossProfit,
    @JsonKey(name: 'margin_pct') @Default(0.0) double marginPct,
    @JsonKey(name: 'total_bills') @Default(0) int totalBills,
  }) = _ProfitSummary;

  factory ProfitSummary.fromJson(Map<String, dynamic> json) =>
      _$ProfitSummaryFromJson(json);
}
