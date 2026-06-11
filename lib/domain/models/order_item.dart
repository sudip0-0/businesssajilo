import 'package:freezed_annotation/freezed_annotation.dart';

part 'order_item.freezed.dart';
part 'order_item.g.dart';

@freezed
abstract class OrderItem with _$OrderItem {
  const factory OrderItem({
    required String id,
    required String orderId,
    required String productId,
    required int qty,
    String? productName,
    String? productNameNp,
    String? unit,
    String? imageUrl,
  }) = _OrderItem;

  factory OrderItem.fromJson(Map<String, dynamic> json) =>
      _$OrderItemFromJson(json);
}
