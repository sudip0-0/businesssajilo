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
    case 'quote_received':
    case 'quote_accepted':
    case 'quote_rejected':
      if (!canViewQuotes) return const NotificationNonNavigable();
      if (ids.orderId != null) {
        // `tab=quote` scrolls the order's quote section into view.
        return NotificationNavigate('/order/${ids.orderId}?tab=quote');
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
    case 'dues_reminder':
      if (role == Role.customer) {
        return const NotificationNavigate('/customer/dues');
      }
      if (role == Role.warehouse) return const NotificationNonNavigable();
      if (ids.customerId == null) return const NotificationNonNavigable();
      return NotificationNavigate('/customers/${ids.customerId}');
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
  if (mobilePath.startsWith('/order/')) {
    if (role == Role.warehouse) return null;
    final raw = mobilePath.substring('/order/'.length);
    final queryIndex = raw.indexOf('?');
    final id = queryIndex == -1 ? raw : raw.substring(0, queryIndex);
    final tab = queryIndex == -1
        ? null
        : Uri.splitQueryString(raw.substring(queryIndex))['tab'];
    final suffix = tab == null ? '' : '?tab=$tab';
    return '$base/orders/$id$suffix';
  }
  if (mobilePath.startsWith('/customers/')) {
    final id = mobilePath.substring('/customers/'.length);
    if (role == Role.owner || role == Role.sales) {
      return '$base/customers/$id';
    }
    return null;
  }
  if (mobilePath == '/customer/dues') {
    if (role == Role.customer) return '/customer/dues';
    return null;
  }
  if (mobilePath.startsWith('/quote/')) {
    // Warehouse has no quote routes on web.
    if (role == Role.warehouse) return null;
    final id = mobilePath.substring('/quote/'.length);
    return '$base/quotes/$id';
  }
  if (mobilePath == '/notifications') {
    return '$base/notifications';
  }
  return null;
}
