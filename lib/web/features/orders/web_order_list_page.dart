import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/ui/status_chip.dart';
import '../../../core/utils/bs_date.dart';
import '../../../domain/models/order.dart';
import '../../../features/orders/order_detail_screen.dart';
import '../../../features/orders/providers.dart';
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

  String get _ordersBasePath {
    final prefix = _webRolePrefix(context);
    return widget.ownOnly ? '$prefix/orders' : '$prefix/orders';
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ordersAsync = widget.ownOnly
        ? ref.watch(ownOrderListProvider)
        : ref.watch(orderQueueProvider);
    final ordersProvider = widget.ownOnly
        ? ownOrderListProvider
        : orderQueueProvider;
    final selectedId = widget.selectedOrderId;

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
            Expanded(
              child: ordersAsync.when(
                loading: () => const WebListSkeleton(),
                error: (_, _) => WebEmptyState(
                  message: l10n.loadingFailed,
                  actionLabel: l10n.tryAgain,
                  onAction: () => ref.invalidate(ordersProvider),
                  icon: PhosphorIconsRegular.warning,
                ),
                data: (orders) {
                  final filtered = _filterOrders(orders);
                  if (filtered.isEmpty) {
                    return WebEmptyState(
                      message: _query.isNotEmpty
                          ? l10n.noSearchResults
                          : l10n.noOrders,
                      icon: PhosphorIconsRegular.shoppingCart,
                      actionLabel: _query.isNotEmpty ? l10n.clearSearch : null,
                      onAction: _query.isNotEmpty
                          ? () => setState(() => _query = '')
                          : null,
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(ordersProvider);
                      if (!widget.ownOnly) {
                        ref.invalidate(pendingOrdersCountProvider);
                        ref.invalidate(openQuotesCountProvider);
                      }
                    },
                    child: WebDataTable<Order>(
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
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
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
                  );
                },
              ),
            ),
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
