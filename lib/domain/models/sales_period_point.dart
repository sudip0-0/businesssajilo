import 'package:freezed_annotation/freezed_annotation.dart';

part 'sales_period_point.freezed.dart';
part 'sales_period_point.g.dart';

@freezed
abstract class SalesPeriodPoint with _$SalesPeriodPoint {
  const factory SalesPeriodPoint({
    required DateTime saleDate,
    @Default(0) int billCount,
    @Default(0) int totalSales,
  }) = _SalesPeriodPoint;

  factory SalesPeriodPoint.fromJson(Map<String, dynamic> json) =>
      _$SalesPeriodPointFromJson(json);
}
