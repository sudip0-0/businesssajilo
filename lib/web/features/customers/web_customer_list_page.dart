import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/ui/paginated_list_state.dart';
import '../../../core/utils/money.dart';
import '../../../data/repositories/customers_repository.dart';
import '../../../domain/models/customer.dart';
import '../../../features/customers/customer_detail_screen.dart';
import '../../../features/customers/providers.dart';
import '../../layout/web_master_detail.dart';
import '../../theme/web_palette.dart';
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

class WebCustomerListPage extends ConsumerStatefulWidget {
  const WebCustomerListPage({
    super.key,
    this.selectedCustomerId,
    this.canEdit = false,
    this.canRecordPayments = false,
  });

  final String? selectedCustomerId;
  final bool canEdit;
  final bool canRecordPayments;

  @override
  ConsumerState<WebCustomerListPage> createState() =>
      _WebCustomerListPageState();
}

enum _CustomerBalanceFilter { all, due, credit, settled }

enum _CustomerSortField { name, balance, date }

class _WebCustomerListPageState extends ConsumerState<WebCustomerListPage> {
  String _query = '';
  PaginatedListState<Customer>? _pager;
  final _scrollController = ScrollController();
  _CustomerBalanceFilter _filter = _CustomerBalanceFilter.all;
  _CustomerSortField _sortField = _CustomerSortField.name;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initPager());
  }

  void _initPager() {
    _pager = PaginatedListState<Customer>(
      loadPage: (offset, limit) => ref
          .read(customersRepositoryProvider)
          .list(
            offset: offset,
            limit: limit,
            query: _query.isEmpty ? null : _query,
          ),
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

  void _onQueryChanged(String value) {
    final next = value.trim().toLowerCase();
    if (next == _query) return;
    setState(() => _query = next);
    _pager?.refresh();
  }

  void _setFilter(_CustomerBalanceFilter filter) {
    if (_filter == filter) return;
    setState(() => _filter = filter);
    if (filter != _CustomerBalanceFilter.all) {
      // Balance filters are applied client-side, so make sure the whole
      // customer list is loaded before showing a filtered view.
      WidgetsBinding.instance.addPostFrameCallback((_) => _pager?.loadAll());
    }
  }

  List<Customer> get _filtered {
    final items = _pager?.items ?? [];
    final filtered = switch (_filter) {
      _CustomerBalanceFilter.all => List<Customer>.from(items),
      _CustomerBalanceFilter.due =>
        items.where((c) => c.balanceDue > 0).toList(),
      _CustomerBalanceFilter.credit =>
        items.where((c) => c.balanceDue < 0).toList(),
      _CustomerBalanceFilter.settled =>
        items.where((c) => c.balanceDue == 0).toList(),
    };
    filtered.sort((a, b) {
      final cmp = switch (_sortField) {
        _CustomerSortField.name =>
          a.shopName.toLowerCase().compareTo(b.shopName.toLowerCase()),
        _CustomerSortField.balance => a.balanceDue.compareTo(b.balanceDue),
        _CustomerSortField.date =>
          (a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
            b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
          ),
      };
      return _sortAscending ? cmp : -cmp;
    });
    return filtered;
  }

  void _selectCustomer(Customer customer) {
    context.go('${_webRolePrefix(context)}/customers/${customer.id}');
  }

  Widget _buildSortControl(AppLocalizations l10n) {
    return PopupMenuButton<_CustomerSortField>(
      initialValue: _sortField,
      tooltip: l10n.sortBy,
      icon: Icon(
        _sortAscending
            ? PhosphorIconsRegular.arrowUp
            : PhosphorIconsRegular.arrowDown,
      ),
      onSelected: (field) {
        if (field == _sortField) {
          setState(() => _sortAscending = !_sortAscending);
        } else {
          setState(() => _sortField = field);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _CustomerSortField.name,
          child: Text(
            l10n.sortName,
            style: TextStyle(
              fontWeight: _sortField == _CustomerSortField.name
                  ? FontWeight.bold
                  : null,
            ),
          ),
        ),
        PopupMenuItem(
          value: _CustomerSortField.balance,
          child: Text(
            l10n.balance,
            style: TextStyle(
              fontWeight: _sortField == _CustomerSortField.balance
                  ? FontWeight.bold
                  : null,
            ),
          ),
        ),
        PopupMenuItem(
          value: _CustomerSortField.date,
          child: Text(
            l10n.sortDate,
            style: TextStyle(
              fontWeight: _sortField == _CustomerSortField.date
                  ? FontWeight.bold
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selectedId = widget.selectedCustomerId;
    final pager = _pager;

    ref.listen<int>(customersRevisionProvider, (prev, next) {
      if (prev != next) {
        _pager?.refresh();
      }
    });

    return WebPageScaffold(
      title: l10n.customers,
      actions: widget.canEdit
          ? [
              FilledButton.icon(
                onPressed: () =>
                    context.go('${_webRolePrefix(context)}/customers/new'),
                icon: const Icon(PhosphorIconsRegular.userPlus),
                label: Text(l10n.addCustomer),
              ),
            ]
          : const [],
      body: WebMasterDetail(
        hasSelection: selectedId != null,
        list: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: WebSearchField(
                hint: l10n.filterCustomers,
                onChanged: _onQueryChanged,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final (filter, label) in [
                          (_CustomerBalanceFilter.all, l10n.allCustomers),
                          (
                            _CustomerBalanceFilter.due,
                            l10n.customerFilterDues,
                          ),
                          (
                            _CustomerBalanceFilter.credit,
                            l10n.creditBalance,
                          ),
                          (
                            _CustomerBalanceFilter.settled,
                            l10n.customerFilterSettled,
                          ),
                        ])
                          FilterChip(
                            label: Text(label),
                            selected: _filter == filter,
                            onSelected: (_) => _setFilter(filter),
                          ),
                      ],
                    ),
                  ),
                  _buildSortControl(l10n),
                ],
              ),
            ),
            Expanded(child: _buildListBody(l10n, pager)),
          ],
        ),
        detail: selectedId == null
            ? null
            : CustomerDetailScreen(
                customerId: selectedId,
                canEdit: widget.canEdit,
                canRecordPayments: widget.canRecordPayments,
                embedded: true,
              ),
      ),
    );
  }

  Widget _buildListBody(
    AppLocalizations l10n,
    PaginatedListState<Customer>? pager,
  ) {
    if (pager == null || pager.initialLoading) {
      return const WebListSkeleton();
    }
    if (pager.error != null && pager.items.isEmpty) {
      return WebEmptyState(
        message: l10n.loadingFailed,
        actionLabel: l10n.tryAgain,
        onAction: () => pager.refresh(),
        icon: PhosphorIconsRegular.warning,
      );
    }
    final items = _filtered;
    if (items.isEmpty) {
      final searching = _query.isNotEmpty;
      final filtering = _filter != _CustomerBalanceFilter.all;
      return WebEmptyState(
        message: searching
            ? l10n.noSearchResults
            : (filtering ? l10n.noMatchingResults : l10n.noCustomers),
        icon: PhosphorIconsRegular.storefront,
        actionLabel: searching
            ? l10n.clearSearch
            : (filtering
                ? l10n.allCustomers
                : (widget.canEdit ? l10n.addCustomer : null)),
        onAction: searching
            ? () {
                setState(() => _query = '');
                pager.refresh();
              }
            : (filtering
                ? () => _setFilter(_CustomerBalanceFilter.all)
                : (widget.canEdit
                    ? () =>
                        context.go('${_webRolePrefix(context)}/customers/new')
                    : null)),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await pager.refresh();
        ref.invalidate(totalDuesProvider);
      },
      child: ListView.separated(
        controller: _scrollController,
        itemCount: items.length + (pager.hasMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 0),
        itemBuilder: (context, index) {
          if (index >= items.length) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: pager.loading
                    ? const CircularProgressIndicator()
                    : TextButton(
                        onPressed: pager.loadMore,
                        child: Text(l10n.loadMore),
                      ),
              ),
            );
          }
          final customer = items[index];
          return _CustomerRow(
            customer: customer,
            selected: widget.selectedCustomerId == customer.id,
            onTap: () => _selectCustomer(customer),
          );
        },
      ),
    );
  }
}

class _CustomerRow extends StatelessWidget {
  const _CustomerRow({
    required this.customer,
    required this.onTap,
    this.selected = false,
  });

  final Customer customer;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context).textTheme;
    final due = customer.balanceDue;
    final subtitle = [
      if (customer.contactName != null) customer.contactName!,
      if (customer.phone != null) customer.phone!,
    ].join(' · ');

    final amountStyle = theme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: due < 0
          ? WebPalette.navy
          : due > 0
          ? WebPalette.danger
          : WebPalette.success,
    );

    return WebHoverableRow(
      selected: selected,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(
              PhosphorIconsRegular.storefront,
              color: WebPalette.navy,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.shopName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                due < 0
                    ? '${l10n.creditBalance} ${formatNpr(Paisa(-due), showPaisa: false)}'
                    : formatNpr(Paisa(due), showPaisa: false),
                style: amountStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
