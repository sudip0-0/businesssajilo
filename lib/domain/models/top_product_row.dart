import 'package:freezed_annotation/freezed_annotation.dart';

part 'top_product_row.freezed.dart';
part 'top_product_row.g.dart';

@freezed
abstract class TopProductRow with _$TopProductRow {
  const factory TopProductRow({
    required String productId,
    required String nameSnapshot,
    @Default(0) int qtySold,
    @Default(0) int revenue,
  }) = _TopProductRow;

  factory TopProductRow.fromJson(Map<String, dynamic> json) =>
      _$TopProductRowFromJson(json);
}
