import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/list_skeleton.dart';
import '../../core/ui/status_chip.dart';
import '../../core/utils/bs_date.dart';
import 'order_detail_screen.dart';
import 'providers.dart';

class OrderListScreen extends ConsumerWidget {
  const OrderListScreen({super.key, this.ownOnly = false});

  final bool ownOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ordersAsync = ownOnly
        ? ref.watch(ownOrderListProvider)
        : ref.watch(staffOrderListProvider);

    final provider = ownOnly ? ownOrderListProvider : staffOrderListProvider;

    return ordersAsync.when(
      loading: () => const ListSkeleton(),
      error: (e, _) => ErrorState(
        message: l10n.loadingFailed,
        onRetry: () => ref.invalidate(provider),
      ),
      data: (orders) {
        if (orders.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(provider),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                EmptyState(
                  icon: Icons.shopping_bag_outlined,
                  message: l10n.noOrders,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(provider),
          child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final order = orders[index];
            final dateStr = order.createdAt != null
                ? BsDate.both(
                    order.createdAt!,
                    locale: Localizations.localeOf(context),
                  )
                : '—';
            return Card(
              child: ListTile(
                title: Text(
                  ownOnly
                      ? dateStr
                      : (order.customerShopName ?? l10n.customers),
                ),
                subtitle: Text(
                  '${order.items.length} · ${l10n.orderItems}',
                ),
                trailing: StatusChip(order.status),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderDetailScreen(orderId: order.id),
                    ),
                  );
                  ref.invalidate(provider);
                },
              ),
            );
          },
          ),
        );
      },
    );
  }
}
