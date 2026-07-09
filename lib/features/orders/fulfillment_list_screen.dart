import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/list_skeleton.dart';
import '../../core/ui/paginated_list_state.dart';
import '../../core/ui/status_chip.dart';
import '../../core/utils/bs_date.dart';
import '../../data/repositories/orders_repository.dart';
import '../../domain/enums.dart';
import '../../domain/models/order.dart';
import 'providers.dart';

class FulfillmentListScreen extends ConsumerStatefulWidget {
  const FulfillmentListScreen({super.key});

  @override
  ConsumerState<FulfillmentListScreen> createState() =>
      _FulfillmentListScreenState();
}

class _FulfillmentListScreenState extends ConsumerState<FulfillmentListScreen> {
  PaginatedListState<Order>? _pager;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initPager());
  }

  void _initPager() {
    final repo = ref.read(ordersRepositoryProvider);
    _pager = PaginatedListState<Order>(
      loadPage: (offset, limit) =>
          repo.fulfillmentQueue(offset: offset, limit: limit),
      onChanged: () {
        if (mounted) setState(() {});
      },
    )..attachScrollController(_scrollController);
    _pager!.refresh().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await _pager?.refresh();
    ref.invalidate(fulfillmentActiveCountProvider);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pager = _pager;

    if (pager == null || pager.initialLoading) {
      return const ListSkeleton();
    }
    if (pager.error != null && pager.items.isEmpty) {
      return ErrorState(message: l10n.loadingFailed, onRetry: _refresh);
    }
    if (pager.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
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

    final active = pager.items;
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: active.length + (pager.hasMore || pager.loading ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index >= active.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
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
                        await _refresh();
                      },
                      child: Text(l10n.markPacked),
                    ),
                  if (order.status == OrderStatus.packed)
                    FilledButton(
                      onPressed: () async {
                        await ref
                            .read(ordersRepositoryProvider)
                            .updateStatus(order.id, OrderStatus.dispatched);
                        await _refresh();
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
  }
}
