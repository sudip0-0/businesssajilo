import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/ui/status_chip.dart';
import '../../data/repositories/orders_repository.dart';
import '../../domain/enums.dart';
import '../auth/providers/auth_provider.dart';
import '../billing/bill_from_order_sheet.dart';
import '../chat/order_chat_screen.dart';
import '../inventory/product_image.dart';
import '../quotes/providers.dart';
import '../quotes/quote_builder_screen.dart';
import '../quotes/quote_detail_screen.dart';
import 'providers.dart';

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final orderAsync = ref.watch(orderDetailProvider(orderId));
    final quotesAsync = ref.watch(orderQuotesProvider(orderId));
    final session = ref.watch(authProvider).value;
    final role = session?.member?.role;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.orderDetail)),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (order) {
          final latestSent = quotesAsync.value
              ?.where((q) => q.status == QuoteStatus.sent)
              .firstOrNull;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.customerShopName ?? l10n.myOrders,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  StatusChip(order.status),
                ],
              ),
              if (order.createdAt != null)
                Text(
                  DateFormat.yMMMd()
                      .add_jm()
                      .format(order.createdAt!.toLocal()),
                ),
              if (order.customerNote != null &&
                  order.customerNote!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(l10n.customerNote,
                    style: Theme.of(context).textTheme.titleSmall),
                Text(order.customerNote!),
              ],
              const SizedBox(height: 16),
              Text(l10n.orderItems,
                  style: Theme.of(context).textTheme.titleMedium),
              const Divider(),
              ...order.items.map(
                (item) => ListTile(
                  leading: ProductImage(
                    storagePath: item.imageUrl,
                    size: 40,
                  ),
                  title: Text(item.productName ?? '—'),
                  trailing: Text('${item.qty} ${item.unit ?? ''}'),
                ),
              ),
              const SizedBox(height: 16),
              _ActionButtons(
                orderId: orderId,
                status: order.status,
                role: role,
                latestSentQuoteId: latestSent?.id,
                customerId: order.customerId,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ActionButtons extends ConsumerWidget {
  const _ActionButtons({
    required this.orderId,
    required this.status,
    required this.role,
    required this.latestSentQuoteId,
    required this.customerId,
  });

  final String orderId;
  final OrderStatus status;
  final Role? role;
  final String? latestSentQuoteId;
  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final canQuote = role?.canQuote ?? false;
    final isCustomer = role == Role.customer;
    final canChat = canQuote || isCustomer;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (canChat)
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderChatScreen(orderId: orderId),
              ),
            ),
            icon: const Icon(Icons.chat_bubble_outline),
            label: Text(l10n.openChat),
          ),
        if (isCustomer && latestSentQuoteId != null)
          FilledButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QuoteDetailScreen(quoteId: latestSentQuoteId!),
                ),
              );
              ref.invalidate(orderDetailProvider(orderId));
              ref.invalidate(orderQuotesProvider(orderId));
            },
            child: Text(l10n.viewQuote),
          ),
        if (canQuote &&
            (status == OrderStatus.placed ||
                status == OrderStatus.quoted ||
                status == OrderStatus.rejected))
          FilledButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QuoteBuilderScreen(orderId: orderId),
                ),
              );
              _invalidate(ref);
            },
            child: Text(
              status == OrderStatus.quoted ? l10n.requote : l10n.sendQuote,
            ),
          ),
        if (canQuote && status == OrderStatus.accepted)
          FilledButton(
            onPressed: () async {
              await ref
                  .read(ordersRepositoryProvider)
                  .updateStatus(orderId, OrderStatus.confirmed);
              _invalidate(ref);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.confirmOrder)),
                );
              }
            },
            child: Text(l10n.confirmOrder),
          ),
        if (canQuote && status == OrderStatus.dispatched)
          FilledButton(
            onPressed: () async {
              final saved = await showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                builder: (_) => BillFromOrderSheet(
                  orderId: orderId,
                  customerId: customerId,
                ),
              );
              if (saved == true) _invalidate(ref);
            },
            child: Text(l10n.generateBill),
          ),
        if (role == Role.warehouse && status == OrderStatus.confirmed)
          FilledButton(
            onPressed: () => _updateStatus(
              context,
              ref,
              OrderStatus.packed,
              l10n.markPacked,
            ),
            child: Text(l10n.markPacked),
          ),
        if (role == Role.warehouse && status == OrderStatus.packed)
          FilledButton(
            onPressed: () => _updateStatus(
              context,
              ref,
              OrderStatus.dispatched,
              l10n.markDispatched,
            ),
            child: Text(l10n.markDispatched),
          ),
      ],
    );
  }

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    OrderStatus next,
    String label,
  ) async {
    await ref.read(ordersRepositoryProvider).updateStatus(orderId, next);
    _invalidate(ref);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(label)));
    }
  }

  void _invalidate(WidgetRef ref) {
    ref.invalidate(orderDetailProvider(orderId));
    ref.invalidate(orderQueueProvider);
    ref.invalidate(staffOrderListProvider);
    ref.invalidate(ownOrderListProvider);
    ref.invalidate(fulfillmentQueueProvider);
    ref.invalidate(pendingOrdersCountProvider);
  }
}
