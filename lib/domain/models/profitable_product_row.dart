import 'package:freezed_annotation/freezed_annotation.dart';

part 'profitable_product_row.freezed.dart';
part 'profitable_product_row.g.dart';

@freezed
abstract class ProfitableProductRow with _$ProfitableProductRow {
  const factory ProfitableProductRow({
    @JsonKey(name: 'product_id') required String productId,
    @JsonKey(name: 'name_snapshot') required String nameSnapshot,
    @JsonKey(name: 'qty_sold') @Default(0) int qtySold,
    @Default(0) int revenue,
    @Default(0) int cogs,
    @JsonKey(name: 'gross_profit') @Default(0) int grossProfit,
    @JsonKey(name: 'margin_pct') @Default(0.0) double marginPct,
  }) = _ProfitableProductRow;

  factory ProfitableProductRow.fromJson(Map<String, dynamic> json) =>
      _$ProfitableProductRowFromJson(json);
}
