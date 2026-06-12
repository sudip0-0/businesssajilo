import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../domain/enums.dart';
import '../../../features/chat/order_chat_screen.dart';
import '../../../features/orders/order_detail_screen.dart';
import '../../../features/orders/providers.dart';
import '../web_page_scaffold.dart';

class WebOrderDetailPage extends ConsumerWidget {
  const WebOrderDetailPage({
    super.key,
    required this.orderId,
    this.initialTab = 0,
    this.ordersListPath = '/owner/orders',
  });

  final String orderId;
  final int initialTab;
  final String ordersListPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final orderAsync = ref.watch(orderDetailProvider(orderId));
    final subtitle = orderAsync.maybeWhen(
      data: (order) => order.customerShopName,
      orElse: () => null,
    );

    return DefaultTabController(
      length: 2,
      initialIndex: initialTab.clamp(0, 1),
      child: WebPageScaffold(
        title: l10n.orderDetail,
        subtitle: subtitle,
        breadcrumbs: [l10n.orders, orderId.substring(0, 8)],
        actions: [
          OutlinedButton.icon(
            onPressed: () => context.go(ordersListPath),
            icon: Icon(PhosphorIconsRegular.arrowLeft),
            label: Text(l10n.orders),
          ),
        ],
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TabBar(
              tabs: [
                Tab(text: l10n.orderDetail, icon: Icon(PhosphorIconsRegular.package)),
                Tab(text: l10n.openChat, icon: Icon(PhosphorIconsRegular.chatCircle)),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  OrderDetailScreen(orderId: orderId, embedded: true),
                  OrderChatScreen(orderId: orderId, embedded: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Resolves the orders list path from the signed-in member role.
String webOrdersListPath(Role? role) => switch (role) {
      Role.owner => '/owner/orders',
      Role.sales => '/sales/orders',
      Role.warehouse => '/warehouse/orders',
      Role.customer => '/customer/orders',
      null => '/login',
    };
