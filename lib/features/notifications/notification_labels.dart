import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../domain/models/notification_item.dart';

String notificationTitle(AppLocalizations l10n, NotificationItem item) {
  return switch (item.type) {
    'order_placed' => l10n.notifOrderPlaced,
    'quote_received' => l10n.notifQuoteReceived,
    'quote_accepted' => l10n.notifQuoteAccepted,
    'quote_rejected' => l10n.notifQuoteRejected,
    'order_status' => l10n.notifOrderStatus,
    'chat_message' => l10n.notifChatMessage,
    'payment_recorded' => l10n.notifPaymentRecorded,
    'low_stock' => l10n.notifLowStock,
    _ => l10n.notifications,
  };
}

IconData notificationIcon(String type) {
  return switch (type) {
    'order_placed' || 'order_status' => Icons.shopping_cart_outlined,
    'quote_received' || 'quote_accepted' || 'quote_rejected' =>
      Icons.request_quote_outlined,
    'chat_message' => Icons.chat_bubble_outline,
    'payment_recorded' => Icons.payments_outlined,
    'low_stock' => Icons.inventory_2_outlined,
    _ => Icons.notifications_outlined,
  };
}
