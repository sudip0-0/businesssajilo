import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/layout/adaptive_scaffold.dart';
import '../../core/layout/two_pane_layout.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/list_skeleton.dart';
import '../../core/ui/paginated_list_state.dart';
import '../../core/utils/money.dart';
import '../../data/repositories/customers_repository.dart';
import '../../domain/enums.dart';
import '../../domain/models/customer.dart';
import '../../core/ui/adaptive_sheet.dart';
import 'add_customer_sheet.dart';
import 'customer_detail_screen.dart';
import 'providers.dart';

enum _CustomerSortField { name, balance, date }

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({
    super.key,
    this.canEdit = false,
    this.canRecordPayments = false,
  });

  final bool canEdit;
  final bool canRecordPayments;

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  static const _searchDebounce = Duration(milliseconds: 300);

  String _query = '';
  Timer? _searchDebounceTimer;
  String? _selectedCustomerId;
  PaginatedListState<Customer>? _pager;
  final _scrollController = ScrollController();
  CustomerBalanceFilter _filter = CustomerBalanceFilter.all;
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
            balanceFilter: _filter,
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
    _searchDebounceTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(_searchDebounce, () {
      if (!mounted) return;
      final next = value.trim().toLowerCase();
      if (next == _query) return;
      setState(() => _query = next);
      _pager?.refresh();
    });
  }

  void _setFilter(CustomerBalanceFilter filter) {
    if (_filter == filter) return;
    setState(() => _filter = filter);
    _pager?.refresh();
  }

  List<Customer> get _filtered {
    final filtered = List<Customer>.from(_pager?.items ?? []);
    filtered.sort((a, b) {
      final cmp = switch (_sortField) {
        _CustomerSortField.name => a.shopName.toLowerCase().compareTo(
          b.shopName.toLowerCase(),
        ),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pager = _pager;

    ref.listen<int>(customersRevisionProvider, (prev, next) {
      if (prev != next) {
        _pager?.refresh();
      }
    });

    final listPane = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            BsSpacing.lg,
            BsSpacing.sm,
            BsSpacing.lg,
            0,
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: l10n.filterCustomers,
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: _onQueryChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
          child: SizedBox(
            height: 48,
            child: ShaderMask(
              shaderCallback: (bounds) {
                return const LinearGradient(
                  colors: [Colors.white, Colors.white, Color(0x00FFFFFF)],
                  stops: [0.0, 0.88, 1.0],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 28, 0),
                children: [
                  for (final (filter, label) in [
                    (CustomerBalanceFilter.all, l10n.allCustomers),
                    (CustomerBalanceFilter.due, l10n.customerFilterDues),
                    (CustomerBalanceFilter.credit, l10n.creditBalance),
                    (CustomerBalanceFilter.settled, l10n.customerFilterSettled),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(label),
                        selected: _filter == filter,
                        onSelected: (_) => _setFilter(filter),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: PopupMenuButton<_CustomerSortField>(
                      initialValue: _sortField,
                      tooltip: l10n.sortBy,
                      icon: Icon(
                        _sortAscending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
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
                              fontWeight:
                                  _sortField == _CustomerSortField.balance
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
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(child: _buildListBody(l10n, pager)),
      ],
    );

    return TwoPaneLayout(
      listPane: listPane,
      detailPane: _selectedCustomerId == null
          ? null
          : CustomerDetailScreen(
              customerId: _selectedCustomerId!,
              canEdit: widget.canEdit,
              canRecordPayments: widget.canRecordPayments,
              embedded: true,
            ),
    );
  }

  Widget _buildListBody(
    AppLocalizations l10n,
    PaginatedListState<Customer>? pager,
  ) {
    if (pager == null || pager.initialLoading) {
      return const ListSkeleton();
    }
    if (pager.error != null && pager.items.isEmpty) {
      return ErrorState(onRetry: () => pager.refresh());
    }
    final items = _filtered;
    if (items.isEmpty) {
      final searching = _query.trim().isNotEmpty;
      final filtering = _filter != CustomerBalanceFilter.all;
      return EmptyState(
        icon: Icons.storefront_outlined,
        message: searching
            ? l10n.noSearchResults
            : (filtering ? l10n.noMatchingResults : l10n.noCustomers),
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
                  ? () => _setFilter(CustomerBalanceFilter.all)
                  : (widget.canEdit ? () => _openAddCustomer(context) : null)),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        await pager.refresh();
        ref.invalidate(totalDuesProvider);
      },
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: BsSpacing.xxl),
        itemCount: items.length + (pager.hasMore ? 1 : 0),
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index >= items.length) {
            return Padding(
              padding: const EdgeInsets.all(BsSpacing.lg),
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
          return _CustomerTile(
            customer: customer,
            selected: _selectedCustomerId == customer.id,
            onTap: () => _selectCustomer(context, customer),
          );
        },
      ),
    );
  }

  void _selectCustomer(BuildContext context, Customer customer) {
    if (isWideLayout(context)) {
      setState(() => _selectedCustomerId = customer.id);
      return;
    }
    _openDetail(context, customer);
  }

  Future<void> _openDetail(BuildContext context, Customer customer) async {
    final refreshed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerDetailScreen(
          customerId: customer.id,
          canEdit: widget.canEdit,
          canRecordPayments: widget.canRecordPayments,
        ),
      ),
    );
    if (refreshed == true) {
      ref.invalidate(customerListProvider);
      ref.invalidate(totalDuesProvider);
    }
  }

  Future<void> _openAddCustomer(BuildContext context) async {
    final created = await showAdaptiveSheet<bool>(
      context: context,
      title: AppLocalizations.of(context).addCustomer,
      child: const AddCustomerSheet(),
    );
    if (created == true) {
      bumpCustomersRevision(ref);
      ref.invalidate(customerListProvider);
      ref.invalidate(totalDuesProvider);
    }
  }
}

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({
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

    final dueLabel = due < 0
        ? '${l10n.creditBalance} ${formatNpr(Paisa(-due), showPaisa: false)}'
        : formatNpr(Paisa(due), showPaisa: false);

    return Semantics(
      button: true,
      selected: selected,
      label: [customer.shopName, dueLabel].join(', '),
      child: ListTile(
        onTap: onTap,
        selected: selected,
        leading: CircleAvatar(
          backgroundColor: BsColors.primary.withValues(alpha: 0.12),
          child: Text(
            customer.shopName.isNotEmpty
                ? customer.shopName[0].toUpperCase()
                : '?',
            style: const TextStyle(color: BsColors.primary),
          ),
        ),
        title: Text(customer.shopName),
        trailing: due < 0
            ? Chip(
                label: Text(
                  '${l10n.creditBalance} ${formatNpr(Paisa(-due), showPaisa: false)}',
                ),
                labelStyle: theme.labelSmall?.copyWith(
                  color: BsColors.primary,
                  fontWeight: FontWeight.w600,
                ),
                visualDensity: VisualDensity.compact,
                side: const BorderSide(color: BsColors.primary),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    due > 0 ? Icons.arrow_upward : Icons.check,
                    size: 14,
                    color: due > 0 ? BsColors.danger : BsColors.success,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    formatNpr(Paisa(due), showPaisa: false),
                    style: theme.titleSmall?.copyWith(
                      color: due > 0 ? BsColors.danger : BsColors.success,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
