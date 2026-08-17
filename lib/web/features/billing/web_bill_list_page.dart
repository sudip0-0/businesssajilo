import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/ui/bill_status_chip.dart';
import '../../../core/ui/debounced_list_search.dart';
import '../../../core/ui/error_state.dart';
import '../../../core/ui/paginated_list_state.dart';
import '../../../core/utils/bill_customer_label.dart';
import '../../../core/utils/money.dart';
import '../../../data/repositories/bills_repository.dart';
import '../../../domain/enums.dart';
import '../../../domain/models/bill.dart';
import '../../../features/billing/bill_date_filter_bar.dart';
import '../../../features/billing/bill_detail_screen.dart';
import '../../../features/billing/providers.dart';
import '../../../features/reports/report_period.dart';
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

class WebBillListPage extends ConsumerStatefulWidget {
  const WebBillListPage({super.key, this.selectedBillId});

  final String? selectedBillId;

  @override
  ConsumerState<WebBillListPage> createState() => _WebBillListPageState();
}

enum _BillStatusFilter { all, paid, partial, due }

enum _BillSortField { date, amount, customer }

class _WebBillListPageState extends ConsumerState<WebBillListPage> {
  PaginatedListState<Bill>? _pager;
  final _scrollController = ScrollController();
  DebouncedListSearchController<Bill>? _search;
  _BillStatusFilter _statusFilter = _BillStatusFilter.all;
  _BillSortField _sortField = _BillSortField.date;
  bool _sortAscending = false;

  /// `null` = all dates; otherwise bills are loaded via [BillsRepository.listInRange].
  ReportPeriod? _datePeriod;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _search = DebouncedListSearchController<Bill>(
        search: _searchBills,
        onChanged: () {
          if (mounted) setState(() {});
        },
      );
      _initPager();
    });
  }

  BillStatus? get _statusParam => switch (_statusFilter) {
    _BillStatusFilter.all => null,
    _BillStatusFilter.paid => BillStatus.paid,
    _BillStatusFilter.partial => BillStatus.partial,
    _BillStatusFilter.due => BillStatus.due,
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
    _pager?.refresh();
    if (_search?.isActive == true) {
      _search!.retry();
    }
  }

  bool get _isFiltering =>
      _statusFilter != _BillStatusFilter.all || _datePeriod != null;

  void _clearFilters() {
    setState(() {
      _statusFilter = _BillStatusFilter.all;
      _datePeriod = null;
    });
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
        _BillSortField.date =>
          (a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
            b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
          ),
        _BillSortField.amount => a.grandTotal.compareTo(b.grandTotal),
        _BillSortField.customer =>
          (a.customerShopName ?? '').toLowerCase().compareTo(
            (b.customerShopName ?? '').toLowerCase(),
          ),
      };
      return _sortAscending ? cmp : -cmp;
    });
    return filtered;
  }

  void _selectBill(Bill bill) {
    context.go('${_webRolePrefix(context)}/billing/${bill.id}');
  }

  Widget _buildSortControl(AppLocalizations l10n) {
    return PopupMenuButton<_BillSortField>(
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
          value: _BillSortField.date,
          child: Text(
            l10n.sortDate,
            style: TextStyle(
              fontWeight: _sortField == _BillSortField.date
                  ? FontWeight.bold
                  : null,
            ),
          ),
        ),
        PopupMenuItem(
          value: _BillSortField.amount,
          child: Text(
            l10n.sortAmount,
            style: TextStyle(
              fontWeight: _sortField == _BillSortField.amount
                  ? FontWeight.bold
                  : null,
            ),
          ),
        ),
        PopupMenuItem(
          value: _BillSortField.customer,
          child: Text(
            l10n.sortCustomer,
            style: TextStyle(
              fontWeight: _sortField == _BillSortField.customer
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
    final prefix = _webRolePrefix(context);
    final selectedId = widget.selectedBillId;
    final pager = _pager;

    ref.listen<int>(billingRevisionProvider, (prev, next) {
      if (prev != next) {
        _pager?.refresh();
        if (_search?.isActive == true) {
          _search!.retry();
        }
      }
    });

    return WebPageScaffold(
      title: l10n.billing,
      actions: [
        FilledButton.icon(
          onPressed: () => context.push('$prefix/billing/new'),
          icon: const Icon(PhosphorIconsRegular.plus),
          label: Text(l10n.newBill),
        ),
      ],
      body: WebMasterDetail(
        hasSelection: selectedId != null,
        list: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: WebSearchField(
                hint: l10n.filterBills,
                onChanged: _onQueryChanged,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final (filter, label) in [
                            (_BillStatusFilter.all, l10n.allBills),
                            (_BillStatusFilter.paid, l10n.paid),
                            (_BillStatusFilter.partial, l10n.partial),
                            (_BillStatusFilter.due, l10n.due),
                          ])
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(label),
                                selected: _statusFilter == filter,
                                onSelected: (_) {
                                  setState(() => _statusFilter = filter);
                                  _pager?.refresh();
                                  if (_search?.isActive == true) {
                                    _search!.retry();
                                  }
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  _buildSortControl(l10n),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: BillDateFilterBar(
                value: _datePeriod,
                onChanged: _onDatePeriodChanged,
              ),
            ),
            Expanded(child: _buildListBody(l10n, pager)),
          ],
        ),
        detail: selectedId == null
            ? null
            : BillDetailScreen(billId: selectedId, embedded: true),
      ),
    );
  }

  Widget _buildListBody(
    AppLocalizations l10n,
    PaginatedListState<Bill>? pager,
  ) {
    if (_search?.isActive == true) {
      final search = _search!;
      if (search.phase == ListSearchPhase.loading) {
        return const WebListSkeleton();
      }
      if (search.phase == ListSearchPhase.error) {
        return ErrorState(message: l10n.loadingFailed, onRetry: search.retry);
      }
      final results = _applyFilters(search.results ?? const <Bill>[]);
      if (results.isEmpty) {
        final filtering = _isFiltering;
        return WebEmptyState(
          message: filtering ? l10n.noMatchingResults : l10n.noSearchResults,
          icon: PhosphorIconsRegular.receipt,
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
        itemCount: results.length,
        separatorBuilder: (_, _) => const SizedBox(height: 0),
        itemBuilder: (context, index) {
          final bill = results[index];
          return _BillRow(
            bill: bill,
            selected: widget.selectedBillId == bill.id,
            onTap: () => _selectBill(bill),
          );
        },
      );
    }

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
    final filtered = _applyFilters(pager.items);
    if (filtered.isEmpty) {
      final filtering = _isFiltering;
      return WebEmptyState(
        message: filtering ? l10n.noMatchingResults : l10n.noBills,
        icon: PhosphorIconsRegular.receipt,
        actionLabel: filtering ? l10n.periodAllDates : l10n.newBill,
        onAction: filtering
            ? _clearFilters
            : () => context.push('${_webRolePrefix(context)}/billing/new'),
      );
    }

    return RefreshIndicator(
      onRefresh: () => pager.refresh(),
      child: ListView.separated(
        controller: _scrollController,
        itemCount: filtered.length + (pager.hasMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 0),
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
          return _BillRow(
            bill: bill,
            selected: widget.selectedBillId == bill.id,
            onTap: () => _selectBill(bill),
          );
        },
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  const _BillRow({
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

    return WebHoverableRow(
      selected: selected,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              bill.pendingSync
                  ? PhosphorIconsRegular.clock
                  : PhosphorIconsRegular.receipt,
              color: bill.pendingSync ? WebPalette.warning : WebPalette.navy,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bill.billNo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    customerLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatNpr(Paisa(bill.grandTotal), showPaisa: false),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                BillStatusChip(bill.status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
