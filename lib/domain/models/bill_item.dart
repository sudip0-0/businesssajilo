import 'package:freezed_annotation/freezed_annotation.dart';

part 'bill_item.freezed.dart';
part 'bill_item.g.dart';

@freezed
abstract class BillItem with _$BillItem {
  const factory BillItem({
    required String id,
    required String billId,
    required String productId,
    required String nameSnapshot,
    required int qty,
    @Default(0) int rate,
    @Default(0) int discount,
    @Default(0) int lineTotal,
  }) = _BillItem;

  factory BillItem.fromJson(Map<String, dynamic> json) =>
      _$BillItemFromJson(json);
}
