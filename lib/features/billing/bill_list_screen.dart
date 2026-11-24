import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/layout/adaptive_scaffold.dart';
import '../../core/layout/two_pane_layout.dart';
import '../../core/preferences/saved_filters_store.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/bill_status_chip.dart';
import '../../core/ui/debounced_list_search.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/list_skeleton.dart';
import '../../core/ui/paginated_list_state.dart';
import '../../core/ui/reset_filters_button.dart';
import '../../core/utils/bill_customer_label.dart';
import '../../core/utils/money.dart';
import '../../data/repositories/bills_repository.dart';
import '../../domain/enums.dart';
import '../../domain/models/bill.dart';
import '../auth/providers/filter_scope_provider.dart';
import '../reports/report_period.dart';
import 'bill_date_filter_bar.dart';
import 'bill_detail_screen.dart';
import 'bill_form_screen.dart';
import 'bill_period_codec.dart';
import 'providers.dart';

class BillListScreen extends ConsumerStatefulWidget {
  const BillListScreen({super.key});

  @override
  ConsumerState<BillListScreen> createState() => _BillListScreenState();
}

class _BillListScreenState extends ConsumerState<BillListScreen> {
  String? _selectedBillId;
  PaginatedListState<Bill>? _pager;
  final _scrollController = ScrollController();
  DebouncedListSearchController<Bill>? _search;
  BillListStatusFilter _statusFilter = BillListStatusFilter.all;
  BillListSortField _sortField = BillListSortField.date;
  bool _sortAscending = false;

  /// `null` = all dates; otherwise bills are loaded via [BillsRepository.listInRange].
  ReportPeriod? _datePeriod;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    _search = DebouncedListSearchController<Bill>(
      search: _searchBills,
      onChanged: () {
        if (mounted) setState(() {});
      },
    );
    final scope = ref.read(currentFilterScopeProvider);
    final saved = await ref.read(savedFiltersStoreProvider).loadBills(scope);
    if (!mounted) return;
    setState(() {
      _statusFilter = saved.status;
      _datePeriod = decodeBillPeriod(saved);
      _sortField = saved.sortField;
      _sortAscending = saved.sortAscending;
    });
    _initPager();
  }

  BillListFilterState get _filterState {
    final encoded = encodeBillPeriod(_datePeriod);
    return BillListFilterState(
      status: _statusFilter,
      periodQuery: encoded.periodQuery,
      customFromMs: encoded.customFromMs,
      customToMs: encoded.customToMs,
      sortField: _sortField,
      sortAscending: _sortAscending,
    );
  }

  void _persistFilters() {
    final scope = ref.read(currentFilterScopeProvider);
    unawaited(
      ref.read(savedFiltersStoreProvider).saveBills(scope, _filterState),
    );
  }

  BillStatus? get _statusParam => switch (_statusFilter) {
    BillListStatusFilter.all => null,
    BillListStatusFilter.paid => BillStatus.paid,
    BillListStatusFilter.partial => BillStatus.partial,
    BillListStatusFilter.due => BillStatus.due,
  };

  Future<List<Bill>> _searchBills(String query) {
    final repo = ref.read(billsRepositoryProvider);
    final period = _datePeriod;
    if (period == null) {
      return repo.search(query, status: _statusParam);
    }
    return repo.listInRange(
      from: period.from,
      to: period.to,
      query: query,
      limit: 50,
      status: _statusParam,
    );
  }

  Future<List<Bill>> _loadBillsPage(int offset, int limit) {
    final repo = ref.read(billsRepositoryProvider);
    final period = _datePeriod;
    if (period == null) {
      return repo.list(offset: offset, limit: limit, status: _statusParam);
    }
    return repo.listInRange(
      from: period.from,
      to: period.to,
      offset: offset,
      limit: limit,
      status: _statusParam,
    );
  }

  void _initPager() {
    _pager = PaginatedListState<Bill>(
      loadPage: _loadBillsPage,
      onChanged: () {
        if (mounted) setState(() {});
      },
    )..attachScrollController(_scrollController);
    _pager!.refresh().then((_) {
      if (mounted) setState(() {});
    });
  }

  void _onDatePeriodChanged(ReportPeriod? period) {
    setState(() => _datePeriod = period);
    _persistFilters();
    _pager?.refresh();
    if (_search?.isActive == true) {
      _search!.retry();
    }
  }

  bool get _isFiltering =>
      _statusFilter != BillListStatusFilter.all || _datePeriod != null;

  void _clearFilters() {
    setState(() {
      _statusFilter = BillListStatusFilter.all;
      _datePeriod = null;
      _sortField = BillListSortField.date;
      _sortAscending = false;
    });
    _persistFilters();
    _pager?.refresh();
    if (_search?.isActive == true) {
      _search!.retry();
    }
  }

  @override
  void dispose() {
    _search?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) => _search?.onQueryChanged(value);

  List<Bill> _applyFilters(List<Bill> bills) {
    final filtered = List<Bill>.from(bills);
    filtered.sort((a, b) {
      final cmp = switch (_sortField) {
        BillListSortField.date =>
          (a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
            b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
          ),
        BillListSortField.amount => a.grandTotal.compareTo(b.grandTotal),
        BillListSortField.customer =>
          (a.customerShopName ?? '').toLowerCase().compareTo(
            (b.customerShopName ?? '').toLowerCase(),
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
    final activeFilterCount = _filterState.activeCount;

    ref.listen<int>(billingRevisionProvider, (prev, next) {
      if (prev != next) {
        _pager?.refresh();
        if (_search?.isActive == true) {
          _search!.retry();
        }
      }
    });

    final listPane = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            decoration: InputDecoration(
              hintText: l10n.filterBills,
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: _onQueryChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    for (final (filter, label) in [
                      (BillListStatusFilter.all, l10n.allBills),
                      (BillListStatusFilter.paid, l10n.paid),
                      (BillListStatusFilter.partial, l10n.partial),
                      (BillListStatusFilter.due, l10n.due),
                    ])
                      FilterChip(
                        label: Text(label),
                        selected: _statusFilter == filter,
                        onSelected: (_) {
                          setState(() => _statusFilter = filter);
                          _persistFilters();
                          _pager?.refresh();
                          if (_search?.isActive == true) {
                            _search!.retry();
                          }
                        },
                      ),
                    if (activeFilterCount > 0)
                      ResetFiltersButton(
                        activeCount: activeFilterCount,
                        onReset: _clearFilters,
                      ),
                  ],
                ),
              ),
              PopupMenuButton<BillListSortField>(
                initialValue: _sortField,
                tooltip: l10n.sortBy,
                icon: Icon(
                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                ),
                onSelected: (field) {
                  setState(() {
                    if (field == _sortField) {
                      _sortAscending = !_sortAscending;
                    } else {
                      _sortField = field;
                    }
                  });
                  _persistFilters();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: BillListSortField.date,
                    child: Text(
                      l10n.sortDate,
                      style: TextStyle(
                        fontWeight: _sortField == BillListSortField.date
                            ? FontWeight.bold
                            : null,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: BillListSortField.amount,
                    child: Text(
                      l10n.sortAmount,
                      style: TextStyle(
                        fontWeight: _sortField == BillListSortField.amount
                            ? FontWeight.bold
                            : null,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: BillListSortField.customer,
                    child: Text(
                      l10n.sortCustomer,
                      style: TextStyle(
                        fontWeight: _sortField == BillListSortField.customer
                            ? FontWeight.bold
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: BillDateFilterBar(
            value: _datePeriod,
            onChanged: _onDatePeriodChanged,
          ),
        ),
        Expanded(child: _buildListBody(l10n, pager)),
      ],
    );

    return TwoPaneLayout(
      listPane: listPane,
      detailPane: _selectedBillId == null
          ? null
          : BillDetailScreen(billId: _selectedBillId!, embedded: true),
    );
  }

  Widget _buildListBody(
    AppLocalizations l10n,
    PaginatedListState<Bill>? pager,
  ) {
    if (_search?.isActive == true) {
      final search = _search!;
      if (search.phase == ListSearchPhase.loading) {
        return const ListSkeleton();
      }
      if (search.phase == ListSearchPhase.error) {
        return ErrorState(message: l10n.loadingFailed, onRetry: search.retry);
      }
      final results = _applyFilters(search.results ?? const <Bill>[]);
      if (results.isEmpty) {
        final filtering = _isFiltering;
        return EmptyState(
          icon: Icons.receipt_long_outlined,
          message: filtering ? l10n.noMatchingResults : l10n.noSearchResults,
          actionLabel: filtering ? l10n.periodAllDates : l10n.clearSearch,
          onAction: () {
            if (filtering) {
              _clearFilters();
            } else {
              _search?.onQueryChanged('');
            }
          },
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.only(bottom: BsSpacing.xxl),
        itemCount: results.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final bill = results[index];
          return _BillTile(
            bill: bill,
            selected: _selectedBillId == bill.id,
            onTap: () => _selectBill(context, bill),
          );
        },
      );
    }
    if (pager == null || pager.initialLoading) {
      return const ListSkeleton();
    }
    if (pager.error != null && pager.items.isEmpty) {
      return ErrorState(onRetry: () => pager.refresh());
    }
    final filtered = _applyFilters(pager.items);
    if (filtered.isEmpty) {
      final filtering = _isFiltering;
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        message: filtering ? l10n.noMatchingResults : l10n.noBills,
        actionLabel: filtering ? l10n.periodAllDates : l10n.newBill,
        onAction: filtering ? _clearFilters : () => _openForm(context),
      );
    }
    return RefreshIndicator(
      onRefresh: () => pager.refresh(),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: BsSpacing.xxl),
        itemCount: filtered.length + (pager.hasMore ? 1 : 0),
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index >= filtered.length) {
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
          final bill = filtered[index];
          return _BillTile(
            bill: bill,
            selected: _selectedBillId == bill.id,
            onTap: () => _selectBill(context, bill),
          );
        },
      ),
    );
  }

  void _selectBill(BuildContext context, Bill bill) {
    if (isWideLayout(context)) {
      setState(() => _selectedBillId = bill.id);
      return;
    }
    _openDetail(context, bill);
  }

  Future<void> _openForm(BuildContext context) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const BillFormScreen()),
    );
    if (saved == true) {
      await _pager?.refresh();
      ref.invalidate(todaysSalesProvider);
      ref.invalidate(todaysBillCountProvider);
    }
  }

  Future<void> _openDetail(BuildContext context, Bill bill) async {
    final changed = await context.push<bool>('/bill/${bill.id}');
    if (changed == true) {
      await _pager?.refresh();
      ref.invalidate(todaysSalesProvider);
      ref.invalidate(todaysBillCountProvider);
    }
  }
}

class _BillTile extends StatelessWidget {
  const _BillTile({
    required this.bill,
    required this.onTap,
    this.selected = false,
  });

  final Bill bill;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final customerLabel = billCustomerLabel(bill, walkInLabel: l10n.walkIn);

    final amountLabel = formatNpr(Paisa(bill.grandTotal), showPaisa: false);
    return Semantics(
      button: true,
      selected: selected,
      label: [
        bill.billNo,
        customerLabel,
        amountLabel,
        bill.status.name,
        if (bill.pendingSync) l10n.provisionalBillNo,
      ].join(', '),
      child: ListTile(
        onTap: onTap,
        selected: selected,
        leading: bill.pendingSync
            ? const Icon(Icons.schedule, color: BsColors.accent)
            : const Icon(Icons.receipt_long_outlined, color: BsColors.primary),
        title: Row(
          children: [
            Expanded(child: Text(bill.billNo)),
            if (bill.pendingSync) ...[
              const SizedBox(width: 4),
              Tooltip(
                message: l10n.provisionalBillNo,
                child: const Icon(
                  Icons.schedule,
                  size: 14,
                  color: BsColors.accent,
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(customerLabel),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              amountLabel,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            BillStatusChip(bill.status),
          ],
        ),
      ),
    );
  }
}
