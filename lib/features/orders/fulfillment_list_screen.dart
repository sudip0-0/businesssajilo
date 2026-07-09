import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/list_skeleton.dart';
import '../../core/ui/status_chip.dart';
import '../../core/utils/bs_date.dart';
import '../../data/repositories/orders_repository.dart';
import '../../domain/enums.dart';
import 'providers.dart';

class FulfillmentListScreen extends ConsumerWidget {
  const FulfillmentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ordersAsync = ref.watch(fulfillmentQueueProvider);

    return ordersAsync.when(
      loading: () => const ListSkeleton(),
      error: (e, _) => ErrorState(
        message: l10n.loadingFailed,
        onRetry: () => ref.invalidate(fulfillmentQueueProvider),
      ),
      data: (orders) {
        final active = orders
            .where((o) => o.status != OrderStatus.dispatched)
            .toList();
        if (active.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(fulfillmentQueueProvider),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                EmptyState(
                  icon: Icons.local_shipping_outlined,
                  message: l10n.emptyFulfillment,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(fulfillmentQueueProvider),
          child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: active.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final order = active[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            order.customerShopName ?? '—',
                            style: Theme.of(context).textTheme.titleMedium,
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
                    const SizedBox(height: 8),
                    if (order.status == OrderStatus.confirmed)
                      FilledButton(
                        onPressed: () async {
                          await ref
                              .read(ordersRepositoryProvider)
                              .updateStatus(order.id, OrderStatus.packed);
                          ref.invalidate(fulfillmentQueueProvider);
                        },
                        child: Text(l10n.markPacked),
                      ),
                    if (order.status == OrderStatus.packed)
                      FilledButton(
                        onPressed: () async {
                          await ref
                              .read(ordersRepositoryProvider)
                              .updateStatus(order.id, OrderStatus.dispatched);
                          ref.invalidate(fulfillmentQueueProvider);
                        },
                        child: Text(l10n.markDispatched),
                      ),
                  ],
                ),
              ),
            );
          },
          ),
        );
      },
    );
  }
}
