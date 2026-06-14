import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/notifications/notification_payload.dart';
import '../../domain/enums.dart';
import '../../domain/models/notification_item.dart';
import '../router/web_role_routes.dart';

/// Navigates to the screen targeted by a notification using go_router,
/// respecting [role] permissions. Targets the role cannot access are ignored.
void openWebNotificationTarget(
  BuildContext context,
  NotificationItem item, {
  Role? role,
}) {
  if (role == null) return;

  final base = webRoleBasePath(role);
  final ids = NotificationPayloadIds.fromItem(item);

  final canViewBills = role.canBill;
  final canViewQuotes = role != Role.warehouse;

  switch (item.type) {
    case 'chat_message':
      if (ids.orderId != null) {
        context.go('$base/orders/${ids.orderId}?tab=1');
      }
    case 'quote_received':
    case 'quote_accepted':
    case 'quote_rejected':
      if (ids.quoteId != null) {
        if (!canViewQuotes) return;
        context.go('$base/quotes/${ids.quoteId}');
      } else if (ids.orderId != null) {
        context.go('$base/orders/${ids.orderId}');
      }
    case 'payment_recorded':
      if (ids.billId != null) {
        if (!canViewBills) return;
        context.go('$base/billing/${ids.billId}');
      }
    case 'low_stock':
      if (ids.productId != null) {
        final inventoryPath = switch (role) {
          Role.warehouse => '$base/stock',
          _ => '$base/inventory',
        };
        context.go('$inventoryPath/${ids.productId}');
      }
    case 'order_placed':
    case 'order_status':
      if (ids.orderId != null) {
        context.go('$base/orders/${ids.orderId}');
      }
    default:
      break;
  }
}
