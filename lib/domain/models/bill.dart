import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums.dart';
import 'bill_item.dart';

part 'bill.freezed.dart';
part 'bill.g.dart';

@freezed
abstract class Bill with _$Bill {
  const factory Bill({
    required String id,
    required String businessId,
    String? customerId,
    String? orderId,
    required String billNo,
    String? devicePrefix,
    @Default(0) int itemsTotal,
    @Default(0) int discount,
    @Default(0) int grandTotal,
    required BillStatus status,
    required String createdBy,
    DateTime? createdAt,
    String? customerShopName,
    @Default([]) List<BillItem> items,
    @Default(false) bool pendingSync,
  }) = _Bill;

  factory Bill.fromJson(Map<String, dynamic> json) => _$BillFromJson(json);
}
