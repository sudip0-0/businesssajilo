import '../../domain/models/notification_item.dart';

/// Parsed IDs from a notification payload — shared by mobile and web navigation.
class NotificationPayloadIds {
  const NotificationPayloadIds({
    this.orderId,
    this.quoteId,
    this.billId,
    this.productId,
  });

  factory NotificationPayloadIds.fromItem(NotificationItem item) {
    final payload = item.payload;
    return NotificationPayloadIds(
      orderId: payload['order_id'] as String?,
      quoteId: payload['quote_id'] as String?,
      billId: payload['bill_id'] as String?,
      productId: payload['product_id'] as String?,
    );
  }

  final String? orderId;
  final String? quoteId;
  final String? billId;
  final String? productId;
}
