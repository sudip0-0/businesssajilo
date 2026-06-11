import 'package:freezed_annotation/freezed_annotation.dart';

part 'stock_valuation_row.freezed.dart';
part 'stock_valuation_row.g.dart';

@freezed
abstract class StockValuationRow with _$StockValuationRow {
  const factory StockValuationRow({
    required String productId,
    required String name,
    @Default(0) int stockCached,
    @Default(0) int costPrice,
    @Default(0) int valuation,
    @Default(false) bool isLowStock,
  }) = _StockValuationRow;

  factory StockValuationRow.fromJson(Map<String, dynamic> json) =>
      _$StockValuationRowFromJson(json);
}
