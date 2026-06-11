import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/status_chip.dart';
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

    return ordersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (orders) {
        if (orders.isEmpty) {
          return EmptyState(
            icon: Icons.shopping_bag_outlined,
            message: l10n.noOrders,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final order = orders[index];
            final dateStr = order.createdAt != null
                ? DateFormat.MMMd().format(order.createdAt!.toLocal())
                : '—';
            return Card(
              child: ListTile(
                title: Text(
                  ownOnly
                      ? dateStr
                      : (order.customerShopName ?? l10n.customers),
                ),
                subtitle: Text(
                  '${order.items.length} ${l10n.orderItems.toLowerCase()}',
                ),
                trailing: StatusChip(order.status),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderDetailScreen(orderId: order.id),
                    ),
                  );
                  ref.invalidate(
                    ownOnly ? ownOrderListProvider : staffOrderListProvider,
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
