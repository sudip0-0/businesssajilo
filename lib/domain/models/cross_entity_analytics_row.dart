import 'package:freezed_annotation/freezed_annotation.dart';

part 'cross_entity_analytics_row.freezed.dart';
part 'cross_entity_analytics_row.g.dart';

@freezed
abstract class CrossEntityAnalyticsRow with _$CrossEntityAnalyticsRow {
  const factory CrossEntityAnalyticsRow({
    required String id,
    required String label,
    @JsonKey(name: 'qty_sold') @Default(0) int qtySold,
    @Default(0) int revenue,
    @JsonKey(name: 'gross_profit') @Default(0) int grossProfit,
  }) = _CrossEntityAnalyticsRow;

  factory CrossEntityAnalyticsRow.fromJson(Map<String, dynamic> json) =>
      _$CrossEntityAnalyticsRowFromJson(json);
}
