import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/ui/paginated_list_state.dart';
import '../../../core/ui/status_chip.dart';
import '../../../core/utils/bs_date.dart';
import '../../../data/repositories/orders_repository.dart';
import '../../../domain/models/order.dart';
import '../../../features/customers/providers.dart';
import '../../../features/orders/order_detail_screen.dart';
import '../../../features/orders/providers.dart';
import '../../../features/orders/staff_order_filter.dart';
import '../../layout/web_master_detail.dart';
import '../../ui/web_data_table.dart';
import '../../ui/web_empty_state.dart';
import '../../ui/web_search_field.dart';
import '../../ui/web_skeleton.dart';
import '../web_page_scaffold.dart';

String _webRolePrefix(BuildContext context) {
  final segments = GoRouterState.of(context).uri.pathSegments;
  if (segments.isEmpty) return '';
  return '/${segments.first}';
}

class WebOrderListPage extends ConsumerStatefulWidget {
  const WebOrderListPage({
    super.key,
    this.selectedOrderId,
    this.ownOnly = false,
  });

  final String? selectedOrderId;
  final bool ownOnly;

  @override
  ConsumerState<WebOrderListPage> createState() => _WebOrderListPageState();
}

class _WebOrderListPageState extends ConsumerState<WebOrderListPage> {
  String _query = '';
  PaginatedListState<Order>? _pager;
  final _scrollController = ScrollController();
  StaffOrderFilter _filter = StaffOrderFilter.needsAction;

  String get _ordersBasePath {
    final prefix = _webRolePrefix(context);
    return '$prefix/orders';
  }

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
          : repo.listForStaff(
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

  void _selectOrder(Order order) {
    context.go('$_ordersBasePath/${order.id}');
  }

  List<Order> _filterOrders(List<Order> orders) {
    if (_query.isEmpty) return orders;
    final q = _query.toLowerCase();
    return orders.where((o) {
      return (o.customerShopName?.toLowerCase().contains(q) ?? false) ||
          o.id.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _refresh() async {
    await _pager?.refresh();
    if (!widget.ownOnly) {
      ref.invalidate(pendingOrdersCountProvider);
      ref.invalidate(openQuotesCountProvider);
    } else {
      ref.invalidate(ownOrderCountProvider);
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selectedId = widget.selectedOrderId;
    final pager = _pager;

    if (widget.ownOnly) {
      final profileAsync = ref.watch(ownCustomerProvider);
      if (profileAsync.hasValue && profileAsync.value == null) {
        return WebPageScaffold(
          title: l10n.orders,
          body: WebEmptyState(
            message: l10n.accountNotLinked,
            icon: PhosphorIconsRegular.userMinus,
          ),
        );
      }
    }

    Widget listBody;
    if (pager == null || pager.initialLoading) {
      listBody = const WebListSkeleton();
    } else if (pager.error != null && pager.items.isEmpty) {
      listBody = WebEmptyState(
        message: l10n.loadingFailed,
        actionLabel: l10n.tryAgain,
        onAction: _refresh,
        icon: PhosphorIconsRegular.warning,
      );
    } else {
      final filtered = _filterOrders(pager.items);
      if (filtered.isEmpty) {
        listBody = WebEmptyState(
          message: _query.isNotEmpty ? l10n.noSearchResults : l10n.noOrders,
          icon: PhosphorIconsRegular.shoppingCart,
          actionLabel: _query.isNotEmpty ? l10n.clearSearch : null,
          onAction: _query.isNotEmpty
              ? () => setState(() => _query = '')
              : null,
        );
      } else {
        listBody = RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              WebDataTable<Order>(
                columns: [
                  DataColumn(label: Text(l10n.customers)),
                  DataColumn(label: Text(l10n.orderItems)),
                  DataColumn(label: Text(l10n.orderQueue)),
                ],
                items: filtered,
                selectedId: selectedId,
                idFor: (o) => o.id,
                onRowTap: _selectOrder,
                rowBuilder: (order, _) {
                  final dateStr = order.createdAt != null
                      ? BsDate.both(
                          order.createdAt!,
                          locale: Localizations.localeOf(context),
                        )
                      : '—';
                  return DataRow(
                    cells: [
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(order.customerShopName ?? '—'),
                            Text(
                              dateStr,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      DataCell(Text('${order.items.length}')),
                      DataCell(StatusChip(order.status)),
                    ],
                  );
                },
              ),
              if (pager.hasMore || pager.loading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        );
      }
    }

    return WebPageScaffold(
      title: l10n.orders,
      body: WebMasterDetail(
        hasSelection: selectedId != null,
        list: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: WebSearchField(
                hint: '${l10n.search} ${l10n.orders}',
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
            ),
            if (!widget.ownOnly)
              StaffOrderFilterBar(value: _filter, onChanged: _setFilter),
            Expanded(child: listBody),
          ],
        ),
        detail: selectedId == null
            ? null
            : Theme(
                data: Theme.of(context).copyWith(
                  appBarTheme: const AppBarTheme(
                    toolbarHeight: 0,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                  ),
                ),
                child: OrderDetailScreen(orderId: selectedId),
              ),
      ),
    );
  }
}
