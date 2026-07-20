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
import '../../domain/models/order.dart';
import 'order_detail_screen.dart';
import 'providers.dart';
import 'staff_order_filter.dart';

class OrderQueueScreen extends ConsumerStatefulWidget {
  const OrderQueueScreen({super.key});

  @override
  ConsumerState<OrderQueueScreen> createState() => _OrderQueueScreenState();
}

class _OrderQueueScreenState extends ConsumerState<OrderQueueScreen> {
  PaginatedListState<Order>? _pager;
  final _scrollController = ScrollController();
  StaffOrderFilter _filter = StaffOrderFilter.needsAction;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initPager());
  }

  void _initPager() {
    final repo = ref.read(ordersRepositoryProvider);
    _pager = PaginatedListState<Order>(
      loadPage: (offset, limit) => repo.listForStaff(
        statuses: _filter.statuses,
        offset: offset,
        limit: limit,
      ),
      onChanged: () {
        if (mounted) setState(() {});
      },
    )..attachScrollController(_scrollController);
    _pager!.refresh().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _setFilter(StaffOrderFilter filter) async {
    if (_filter == filter) return;
    setState(() => _filter = filter);
    await _refresh();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await _pager?.refresh();
    ref.invalidate(pendingOrdersCountProvider);
    ref.invalidate(openQuotesCountProvider);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pager = _pager;

    Widget listBody;
    if (pager == null || pager.initialLoading) {
      listBody = const ListSkeleton();
    } else if (pager.error != null && pager.items.isEmpty) {
      listBody = ErrorState(message: l10n.loadingFailed, onRetry: _refresh);
    } else if (pager.items.isEmpty) {
      listBody = RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            EmptyState(
              icon: Icons.shopping_cart_outlined,
              message: l10n.noOrders,
            ),
          ],
        ),
      );
    } else {
      final orders = pager.items;
      listBody = RefreshIndicator(
        onRefresh: _refresh,
        child: ListView.separated(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: orders.length + (pager.hasMore || pager.loading ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            if (index >= orders.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final order = orders[index];
            final dateStr = order.createdAt != null
                ? BsDate.both(
                    order.createdAt!,
                    locale: Localizations.localeOf(context),
                  )
                : '—';
            return Card(
              child: ListTile(
                title: Text(order.customerShopName ?? '—'),
                subtitle: Text(dateStr),
                trailing: StatusChip(order.status),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderDetailScreen(orderId: order.id),
                    ),
                  );
                  await _refresh();
                },
              ),
            );
          },
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StaffOrderFilterBar(value: _filter, onChanged: _setFilter),
        Expanded(child: listBody),
      ],
    );
  }
}
