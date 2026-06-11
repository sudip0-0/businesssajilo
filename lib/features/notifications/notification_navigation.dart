import 'package:flutter/material.dart';

import '../../domain/models/notification_item.dart';
import '../billing/bill_detail_screen.dart';
import '../chat/order_chat_screen.dart';
import '../inventory/product_detail_screen.dart';
import '../orders/order_detail_screen.dart';
import '../quotes/quote_detail_screen.dart';

void openNotificationTarget(BuildContext context, NotificationItem item) {
  final payload = item.payload;
  final orderId = payload['order_id'] as String?;
  final quoteId = payload['quote_id'] as String?;
  final billId = payload['bill_id'] as String?;
  final productId = payload['product_id'] as String?;

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
