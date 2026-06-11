import 'package:flutter/material.dart';

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
  final payload = item.payload;
  final orderId = payload['order_id'] as String?;
  final quoteId = payload['quote_id'] as String?;
  final billId = payload['bill_id'] as String?;
  final productId = payload['product_id'] as String?;

  // Role guards: warehouse/customer never see bill detail; warehouse never
  // sees quote detail.
  final canViewBills = role == null || role.canBill;
  final canViewQuotes = role == null || role != Role.warehouse;

  switch (item.type) {
    case 'chat_message':
      if (orderId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderChatScreen(orderId: orderId),
          ),
        );
      }
    case 'quote_received':
    case 'quote_accepted':
    case 'quote_rejected':
      if (quoteId != null) {
        if (!canViewQuotes) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QuoteDetailScreen(quoteId: quoteId),
          ),
        );
      } else if (orderId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(orderId: orderId),
          ),
        );
      }
    case 'payment_recorded':
      if (billId != null) {
        if (!canViewBills) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BillDetailScreen(billId: billId),
          ),
        );
      }
    case 'low_stock':
      if (productId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(
              productId: productId,
              canEditProduct: false,
              canManageStock: false,
            ),
          ),
        );
      }
    case 'order_placed':
    case 'order_status':
      if (orderId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(orderId: orderId),
          ),
        );
      }
    default:
      break;
  }
}
