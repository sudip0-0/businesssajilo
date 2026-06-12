import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/enums.dart';
import '../../domain/models/notification_item.dart';

/// Role-scoped URL prefix for web navigation.
String webRoleBasePath(Role role) => switch (role) {
      Role.owner => '/owner',
      Role.sales => '/sales',
      Role.warehouse => '/warehouse',
      Role.customer => '/customer',
    };

/// Navigates to the screen targeted by a notification using go_router,
/// respecting [role] permissions. Targets the role cannot access are ignored.
void openWebNotificationTarget(
  BuildContext context,
  NotificationItem item, {
  Role? role,
}) {
  if (role == null) return;

  final base = webRoleBasePath(role);
  final payload = item.payload;
  final orderId = payload['order_id'] as String?;
  final quoteId = payload['quote_id'] as String?;
  final billId = payload['bill_id'] as String?;
  final productId = payload['product_id'] as String?;

  final canViewBills = role.canBill;
  final canViewQuotes = role != Role.warehouse;

  switch (item.type) {
    case 'chat_message':
      if (orderId != null) {
        context.go('$base/orders/$orderId?tab=1');
      }
    case 'quote_received':
    case 'quote_accepted':
    case 'quote_rejected':
      if (quoteId != null) {
        if (!canViewQuotes) return;
        context.go('$base/quotes/$quoteId');
      } else if (orderId != null) {
        context.go('$base/orders/$orderId');
      }
    case 'payment_recorded':
      if (billId != null) {
        if (!canViewBills) return;
        context.go('$base/billing/$billId');
      }
    case 'low_stock':
      if (productId != null) {
        final inventoryPath = switch (role) {
          Role.warehouse => '$base/stock',
          _ => '$base/inventory',
        };
        context.go('$inventoryPath/$productId');
      }
    case 'order_placed':
    case 'order_status':
      if (orderId != null) {
        context.go('$base/orders/$orderId');
      }
    default:
      break;
  }
}
