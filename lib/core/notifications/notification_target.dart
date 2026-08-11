import '../../domain/enums.dart';
import '../../domain/models/notification_item.dart';
import 'notification_payload.dart';

/// Resolved deep-link target for a notification.
sealed class NotificationTarget {
  const NotificationTarget();
}

final class NotificationNavigate extends NotificationTarget {
  const NotificationNavigate(this.path);
  final String path;
}

final class NotificationNonNavigable extends NotificationTarget {
  const NotificationNonNavigable();
}

/// Maps a notification + role to a registered path (or an explicit no-op).
///
/// Mobile and web adapters turn [NotificationNavigate.path] into
/// `context.push` / `context.go` with their own path prefixes when needed.
NotificationTarget resolveNotificationTarget(
  NotificationItem item, {
  Role? role,
}) {
  final ids = NotificationPayloadIds.fromItem(item);
  // Staff who can create bills + customers (own bills via RLS).
  final canViewBills =
      role == null || role.canCreateBills || role == Role.customer;
  final canViewQuotes = role == null || role != Role.warehouse;

  switch (item.type) {
    case 'chat_message':
      if (ids.orderId == null) return const NotificationNonNavigable();
      return NotificationNavigate('/order/${ids.orderId}');
    case 'quote_received':
    case 'quote_accepted':
    case 'quote_rejected':
      if (!canViewQuotes) return const NotificationNonNavigable();
      if (ids.orderId != null) {
        return NotificationNavigate('/order/${ids.orderId}');
      }
      return const NotificationNonNavigable();
    case 'payment_recorded':
      if (ids.billId == null || !canViewBills) {
        return const NotificationNonNavigable();
      }
      return NotificationNavigate('/bill/${ids.billId}');
    case 'low_stock':
    case 'negative_stock':
      if (ids.productId == null) return const NotificationNonNavigable();
      if (role == Role.customer) return const NotificationNonNavigable();
      return NotificationNavigate('/product/${ids.productId}');
    case 'order_placed':
    case 'order_received':
    case 'order_status':
      if (ids.orderId == null) return const NotificationNonNavigable();
      return NotificationNavigate('/order/${ids.orderId}');
    default:
      return const NotificationNonNavigable();
  }
}

/// Web-relative path for an absolute mobile-style notification path.
String? webPathForNotificationTarget({
  required Role role,
  required String mobilePath,
}) {
  final base = switch (role) {
    Role.owner => '/owner',
    Role.sales => '/sales',
    Role.warehouse => '/warehouse',
    Role.customer => '/customer',
  };

  if (mobilePath.startsWith('/bill/')) {
    final id = mobilePath.substring('/bill/'.length);
    if (role == Role.customer || role.canCreateBills) {
      return '$base/billing/$id';
    }
    return null;
  }
  if (mobilePath.startsWith('/product/')) {
    final id = mobilePath.substring('/product/'.length);
    // Owner: /owner/inventory; sales + warehouse: /{role}/stock.
    final inventoryPath = switch (role) {
      Role.owner => '$base/inventory',
      Role.sales || Role.warehouse => '$base/stock',
      Role.customer => null,
    };
    if (inventoryPath == null) return null;
    return '$inventoryPath/$id';
  }
  if (mobilePath.startsWith('/order/') && mobilePath.endsWith('/chat')) {
    // Warehouse has no orders routes on web.
    if (role == Role.warehouse) return null;
    final orderId = mobilePath
        .substring('/order/'.length)
        .replaceAll('/chat', '');
    return '$base/orders/$orderId?tab=1';
  }
  if (mobilePath.startsWith('/order/')) {
    if (role == Role.warehouse) return null;
    final id = mobilePath.substring('/order/'.length);
    return '$base/orders/$id';
  }
  if (mobilePath.startsWith('/quote/')) {
    // No dedicated /quotes routes on web; quote notifs resolve to /order/.
    return null;
  }
  if (mobilePath == '/notifications') {
    return '$base/notifications';
  }
  return null;
}
