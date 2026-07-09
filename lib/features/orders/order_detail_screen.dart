import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/order_status_timeline.dart';
import '../../core/ui/status_chip.dart';
import '../../core/utils/bs_date.dart';
import '../../core/utils/money.dart';
import '../../data/repositories/orders_repository.dart';
import '../../domain/enums.dart';
import '../../domain/models/order_item.dart';
import '../auth/providers/auth_provider.dart';
import '../../web/ui/web_sheet_bridge.dart';
import '../billing/bill_from_order_sheet.dart';
import '../chat/order_chat_screen.dart';
import '../inventory/product_image.dart';
import '../quotes/providers.dart';
import '../quotes/quote_builder_screen.dart';
import '../quotes/quote_detail_screen.dart';
import 'cart_sheet.dart';
import 'catalog_screen.dart';
import 'providers.dart';

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({
    super.key,
    required this.orderId,
    this.embedded = false,
  });

  final String orderId;
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final orderAsync = ref.watch(orderDetailProvider(orderId));
    final quotesAsync = ref.watch(orderQuotesProvider(orderId));
    final session = ref.watch(authProvider).value;
    final role = session?.member?.role;

    final body = orderAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorState(
        message: l10n.loadingFailed,
        onRetry: () => ref.invalidate(orderDetailProvider(orderId)),
      ),
      data: (order) {
        final latestSent = quotesAsync.value
            ?.where((q) => q.status == QuoteStatus.sent)
            .firstOrNull;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            OrderStatusTimeline(status: order.status),
            const SizedBox(height: 16),
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
                BsDate.both(
                  order.createdAt!,
                  locale: Localizations.localeOf(context),
                ),
              ),
            if (order.customerNote != null &&
                order.customerNote!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                l10n.customerNote,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(order.customerNote!),
            ],
            const SizedBox(height: 16),
            Text(
              l10n.orderItems,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Divider(),
            ...order.items.map(
              (item) => ListTile(
                leading: ProductImage(storagePath: item.imageUrl, size: 40),
                title: Text(item.productName ?? '—'),
                trailing: Text('${item.qty} ${item.unit ?? ''}'),
              ),
            ),
            if ((quotesAsync.value ?? const []).isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                l10n.viewQuote,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Divider(),
              ...quotesAsync.value!.map((quote) {
                final superseded = quote.status == QuoteStatus.superseded;
                final greyed = Theme.of(context).disabledColor;
                return ListTile(
                  enabled: !superseded,
                  title: Text(
                    l10n.quoteVersion(quote.version),
                    style: superseded ? TextStyle(color: greyed) : null,
                  ),
                  subtitle: Text(
                    quote.status.name,
                    style: superseded ? TextStyle(color: greyed) : null,
                  ),
                  trailing: Text(
                    formatNpr(Paisa(quote.total), showPaisa: false),
                    style: superseded ? TextStyle(color: greyed) : null,
                  ),
                  onTap: superseded
                      ? null
                      : () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  QuoteDetailScreen(quoteId: quote.id),
                            ),
                          );
                          ref.invalidate(orderDetailProvider(orderId));
                          ref.invalidate(orderQuotesProvider(orderId));
                        },
                );
              }),
            ],
            const SizedBox(height: 16),
            _ActionButtons(
              orderId: orderId,
              status: order.status,
              role: role,
              latestSentQuoteId: latestSent?.id,
              customerId: order.customerId,
              items: order.items,
            ),
          ],
        );
      },
    );

    if (embedded) return body;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.orderDetail)),
      body: body,
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
    required this.items,
  });

  final String orderId;
  final OrderStatus status;
  final Role? role;
  final String? latestSentQuoteId;
  final String customerId;
  final List<OrderItem> items;

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
        if (isCustomer && items.isNotEmpty)
          OutlinedButton.icon(
            onPressed: () => _reorder(context, ref),
            icon: const Icon(Icons.replay_outlined),
            label: Text(l10n.reorder),
          ),
        if (isCustomer && latestSentQuoteId != null)
          FilledButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      QuoteDetailScreen(quoteId: latestSentQuoteId!),
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
            onPressed: () => _updateStatus(
              context,
              ref,
              OrderStatus.confirmed,
              l10n.confirmOrder,
            ),
            child: Text(l10n.confirmOrder),
          ),
        if (canQuote && status == OrderStatus.billed)
          OutlinedButton(
            onPressed: () => _updateStatus(
              context,
              ref,
              OrderStatus.closed,
              l10n.closeOrder,
            ),
            child: Text(l10n.closeOrder),
          ),
        if (canQuote && status == OrderStatus.dispatched)
          FilledButton(
            onPressed: () async {
              final saved = await showAdaptiveSheet<bool>(
                context: context,
                title: l10n.generateBill,
                child: BillFromOrderSheet(
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

  /// One-tap repeat purchase: prefill a cart with this order's items and
  /// open the place-order sheet. Products no longer in the catalog
  /// (deactivated) are skipped with a notice.
  Future<void> _reorder(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final catalog = await ref.read(catalogListProvider.future);
    if (!context.mounted) return;

    final catalogById = {for (final p in catalog) p.id: p};
    final quantities = <String, int>{};
    var skipped = 0;
    for (final item in items) {
      if (catalogById.containsKey(item.productId)) {
        quantities[item.productId] =
            (quantities[item.productId] ?? 0) + item.qty;
      } else {
        skipped++;
      }
    }

    if (skipped > 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.removedUnavailableItems)));
    }
    if (quantities.isEmpty) return;

    final placed = await showAdaptiveSheet<bool>(
      context: context,
      title: l10n.placeOrder,
      child: CartSheet(
        products: quantities.keys.map((id) => catalogById[id]!).toList(),
        quantities: quantities,
      ),
    );
    if (placed == true) {
      ref.invalidate(ownOrderListProvider);
      ref.invalidate(ownOrderCountProvider);
    }
  }

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    OrderStatus next,
    String label,
  ) async {
    final l10n = AppLocalizations.of(context);
    // Forward workflow steps apply immediately; only cancel/close confirm.
    final needsConfirm =
        next == OrderStatus.cancelled || next == OrderStatus.closed;
    if (needsConfirm) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(label),
          content: Text(l10n.areYouSure),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(label),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
    }
    try {
      await ref.read(ordersRepositoryProvider).updateStatus(orderId, next);
      _invalidate(ref);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(label)));
      }
    } on OrderStatusException {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.invalidStatusChange)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.actionFailed)));
      }
    }
  }

  void _invalidate(WidgetRef ref) {
    ref.invalidate(orderDetailProvider(orderId));
    ref.invalidate(orderQueueProvider);
    ref.invalidate(staffOrderListProvider);
    ref.invalidate(ownOrderListProvider);
    ref.invalidate(ownOrderCountProvider);
    ref.invalidate(fulfillmentQueueProvider);
    ref.invalidate(fulfillmentActiveCountProvider);
    ref.invalidate(pendingOrdersCountProvider);
  }
}
