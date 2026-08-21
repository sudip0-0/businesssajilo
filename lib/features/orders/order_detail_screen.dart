import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_failure.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/ui/adaptive_sheet.dart';
import '../../core/ui/bs_snackbar.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/order_status_timeline.dart';
import '../../core/ui/status_chip.dart';
import '../../core/ui/submit_action.dart';
import '../../core/utils/bs_date.dart';
import '../../data/repositories/orders_repository.dart';
import '../../domain/enums.dart';
import '../../domain/models/catalog_product.dart';
import '../../domain/models/order_item.dart';
import '../auth/providers/auth_provider.dart';
import '../billing/bill_from_order_sheet.dart';
import '../inventory/product_image.dart';
import '../quotes/order_quote_section.dart';
import 'cart_sheet.dart';
import 'catalog_screen.dart';
import 'providers.dart';

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({
    super.key,
    required this.orderId,
    this.embedded = false,
    this.anchorQuotes = false,
  });

  final String orderId;
  final bool embedded;

  /// Scroll the quote section into view (notification deep links).
  final bool anchorQuotes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final orderAsync = ref.watch(orderDetailProvider(orderId));
    final session = ref.watch(authProvider).value;
    final role = session?.member?.role;

    final body = orderAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorState(
        message: l10n.loadingFailed,
        onRetry: () => ref.invalidate(orderDetailProvider(orderId)),
      ),
      data: (order) {
        final catalogById = {
          for (final p
              in ref.watch(catalogListProvider).value ??
                  const <CatalogProduct>[])
            p.id: p,
        };
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
            ...order.items.map((item) {
              final catalog = catalogById[item.productId];
              final name =
                  item.productName ??
                  catalog?.name ??
                  item.productNameNp ??
                  '—';
              final unit = item.unit ?? catalog?.unit;
              final imageUrl = item.imageUrl ?? catalog?.imageUrl;
              return ListTile(
                leading: ProductImage(storagePath: imageUrl, size: 40),
                title: Text(name),
                trailing: Text('${item.qty}${unit != null ? ' $unit' : ''}'),
              );
            }),
            const SizedBox(height: 16),
            if (anchorQuotes) _QuoteAnchor(orderId: orderId) else OrderQuoteSection(orderId: orderId),
            _ActionButtons(
              orderId: orderId,
              status: order.status,
              role: role,
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

/// Scrolls the quote section into view for `?tab=quote` deep links.
class _QuoteAnchor extends StatefulWidget {
  const _QuoteAnchor({required this.orderId});

  final String orderId;

  @override
  State<_QuoteAnchor> createState() => _QuoteAnchorState();
}

class _QuoteAnchorState extends State<_QuoteAnchor> {
  final _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _key.currentContext;
      if (ctx != null && mounted) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 300),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) =>
      Container(key: _key, child: OrderQuoteSection(orderId: widget.orderId));
}

class _ActionButtons extends ConsumerWidget {
  const _ActionButtons({
    required this.orderId,
    required this.status,
    required this.role,
    required this.customerId,
    required this.items,
  });

  final String orderId;
  final OrderStatus status;
  final Role? role;
  final String customerId;
  final List<OrderItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final canBill = role?.canBill ?? false;
    final isCustomer = role == Role.customer;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (isCustomer && items.isNotEmpty)
          OutlinedButton.icon(
            onPressed: () => _reorder(context, ref),
            icon: const Icon(Icons.replay_outlined),
            label: Text(l10n.reorder),
          ),
        if (canBill && status == OrderStatus.placed)
          FilledButton(
            onPressed: () => _updateStatus(
              context,
              ref,
              OrderStatus.received,
              l10n.markAsReceived,
            ),
            child: Text(l10n.markAsReceived),
          ),
        if (canBill && status != OrderStatus.billed)
          FilledButton(
            onPressed: () async {
              if (kIsWeb) {
                final segments = GoRouterState.of(context).uri.pathSegments;
                final prefix = segments.isNotEmpty
                    ? '/${segments.first}'
                    : '/owner';
                await context.push('$prefix/billing/new?orderId=$orderId');
                _invalidate(ref);
                return;
              }
              final saved = await showAdaptiveSheet<bool>(
                context: context,
                title: l10n.makeThisBill,
                child: BillFromOrderSheet(
                  orderId: orderId,
                  customerId: customerId,
                ),
              );
              if (saved == true) _invalidate(ref);
            },
            child: Text(l10n.makeThisBill),
          ),
      ],
    );
  }

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
      showBsSnackBar(context, message: l10n.removedUnavailableItems);
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
    await runSubmitAction(
      context,
      action: () async {
        try {
          await ref.read(ordersRepositoryProvider).updateStatus(orderId, next);
          _invalidate(ref);
        } on OrderStatusException {
          throw AppFailure.validation(detail: l10n.invalidStatusChange);
        }
      },
      successMessage: label,
    );
  }

  void _invalidate(WidgetRef ref) {
    ref.invalidate(orderDetailProvider(orderId));
    ref.invalidate(orderQueueProvider);
    ref.invalidate(staffOrderListProvider);
    ref.invalidate(ownOrderListProvider);
    ref.invalidate(ownOrderCountProvider);
    ref.invalidate(pendingOrdersCountProvider);
  }
}
