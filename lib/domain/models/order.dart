import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums.dart';
import 'order_item.dart';

part 'order.freezed.dart';
part 'order.g.dart';

@freezed
abstract class Order with _$Order {
  const factory Order({
    required String id,
    required String businessId,
    required String customerId,
    required OrderStatus status,
    String? customerNote,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? customerShopName,
    @Default([]) List<OrderItem> items,
  }) = _Order;

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
}
