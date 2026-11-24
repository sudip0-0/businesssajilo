import '../../domain/models/notification_item.dart';

/// Parsed IDs from a notification payload — shared by mobile and web navigation.
class NotificationPayloadIds {
  const NotificationPayloadIds({
    this.orderId,
    this.quoteId,
    this.billId,
    this.productId,
    this.customerId,
  });

  /// Single URL path segment ID (UUID or short identifier): rejects path
  /// separators, `..`, query/fragment markers, and control characters so
  /// untrusted notification payloads cannot inject routes.
  static final _safeIdPattern = RegExp(r'^[A-Za-z0-9_-]{1,128}$');

  static String? _safeId(Object? raw) {
    if (raw is! String) return null;
    final trimmed = raw.trim();
    if (!_safeIdPattern.hasMatch(trimmed)) return null;
    return trimmed;
  }

  factory NotificationPayloadIds.fromItem(NotificationItem item) {
    final payload = item.payload;
    return NotificationPayloadIds(
      orderId: _safeId(payload['order_id']),
      quoteId: _safeId(payload['quote_id']),
      billId: _safeId(payload['bill_id']),
      productId: _safeId(payload['product_id']),
      customerId: _safeId(payload['customer_id']),
    );
  }

  final String? orderId;
  final String? quoteId;
  final String? billId;
  final String? productId;
  final String? customerId;
}
