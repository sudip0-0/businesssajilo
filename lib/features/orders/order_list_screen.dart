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
import '../customers/providers.dart';
import 'order_detail_screen.dart';

class OrderListScreen extends ConsumerStatefulWidget {
  const OrderListScreen({super.key, this.ownOnly = false});

  final bool ownOnly;

  @override
  ConsumerState<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends ConsumerState<OrderListScreen> {
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
      loadPage: (offset, limit) => widget.ownOnly
          ? repo.listOwn(offset: offset, limit: limit)
          : repo.listForStaff(offset: offset, limit: limit),
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
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pager = _pager;

    if (widget.ownOnly) {
      final profileAsync = ref.watch(ownCustomerProvider);
      if (profileAsync.isLoading && pager == null) {
        return const ListSkeleton();
      }
      if (profileAsync.hasValue && profileAsync.value == null) {
        return EmptyState(
          icon: Icons.person_off_outlined,
          message: l10n.accountNotLinked,
        );
      }
    }

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
              icon: Icons.shopping_bag_outlined,
              message: l10n.noOrders,
            ),
          ],
        ),
      );
    }

    final orders = pager.items;
    return RefreshIndicator(
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
              title: Text(
                widget.ownOnly ? dateStr : (order.customerShopName ?? '—'),
              ),
              subtitle: widget.ownOnly
                  ? Text('${order.items.length} ${l10n.orderItems}')
                  : Text(dateStr),
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
}
