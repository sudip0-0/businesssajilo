import 'package:flutter/material.dart';

import '../../core/notifications/notification_payload.dart';
import '../../domain/enums.dart';
import '../../domain/models/notification_item.dart';
import '../billing/bill_detail_screen.dart';
import '../chat/order_chat_screen.dart';
import '../inventory/product_detail_screen.dart';
import '../orders/order_detail_screen.dart';
import '../quotes/quote_detail_screen.dart';

/// Navigates to the screen targeted by a notification, respecting [role]
/// permissions. Targets the role cannot access are ignored silently.
void openNotificationTarget(
  BuildContext context,
  NotificationItem item, {
  Role? role,
}) {
  final ids = NotificationPayloadIds.fromItem(item);

  // Role guards: warehouse/customer never see bill detail; warehouse never
  // sees quote detail.
  final canViewBills = role == null || role.canBill;
  final canViewQuotes = role == null || role != Role.warehouse;

  switch (item.type) {
    case 'chat_message':
      if (ids.orderId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderChatScreen(orderId: ids.orderId!),
          ),
        );
      }
    case 'quote_received':
    case 'quote_accepted':
    case 'quote_rejected':
      if (ids.quoteId != null) {
        if (!canViewQuotes) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QuoteDetailScreen(quoteId: ids.quoteId!),
          ),
        );
      } else if (ids.orderId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(orderId: ids.orderId!),
          ),
        );
      }
    case 'payment_recorded':
      if (ids.billId != null) {
        if (!canViewBills) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BillDetailScreen(billId: ids.billId!),
          ),
        );
      }
    case 'low_stock':
      if (ids.productId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(
              productId: ids.productId!,
              canEditProduct: false,
              canManageStock: false,
            ),
          ),
        );
      }
    case 'order_placed':
    case 'order_status':
      if (ids.orderId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(orderId: ids.orderId!),
          ),
        );
      }
    default:
      break;
  }
}
