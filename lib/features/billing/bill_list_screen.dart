import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/layout/adaptive_scaffold.dart';
import '../../core/layout/two_pane_layout.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/bill_status_chip.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/list_skeleton.dart';
import '../../core/ui/paginated_list_state.dart';
import '../../core/utils/money.dart';
import '../../data/repositories/bills_repository.dart';
import '../../domain/models/bill.dart';
import 'bill_detail_screen.dart';
import 'bill_form_screen.dart';
import 'providers.dart';

class BillListScreen extends ConsumerStatefulWidget {
  const BillListScreen({super.key});

  @override
  ConsumerState<BillListScreen> createState() => _BillListScreenState();
}

class _BillListScreenState extends ConsumerState<BillListScreen> {
  String _query = '';
  String? _selectedBillId;
  PaginatedListState<Bill>? _pager;
  final _scrollController = ScrollController();
  Timer? _searchDebounce;
  List<Bill>? _searchResults;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initPager());
  }

  void _initPager() {
    _pager = PaginatedListState<Bill>(
      loadPage: (offset, limit) =>
          ref.read(billsRepositoryProvider).list(offset: offset, limit: limit),
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
    _searchDebounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _query = value.trim();
    _searchDebounce?.cancel();
    if (_query.isEmpty) {
      setState(() {
        _searchResults = null;
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    _searchDebounce = Timer(const Duration(milliseconds: 350), _runSearch);
  }

  Future<void> _runSearch() async {
    final query = _query;
    try {
      final results = await ref.read(billsRepositoryProvider).search(query);
      if (!mounted || _query != query) return;
      setState(() {
        _searchResults = results;
        _searching = false;
      });
    } catch (_) {
      if (!mounted || _query != query) return;
      setState(() {
        _searchResults = const [];
        _searching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pager = _pager;

    ref.listen<int>(billingRevisionProvider, (prev, next) {
      if (prev != next) {
        _pager?.refresh();
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
    if (_query.isNotEmpty) {
      if (_searching && _searchResults == null) {
        return const ListSkeleton();
      }
      final results = _searchResults ?? const <Bill>[];
      if (results.isEmpty) {
        return EmptyState(
          icon: Icons.receipt_long_outlined,
          message: l10n.noSearchResults,
          actionLabel: l10n.clearSearch,
          onAction: () => setState(() {
            _query = '';
            _searchResults = null;
          }),
        );
      }
      return ListView.separated(
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
    final filtered = pager.items;
    if (filtered.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        message: l10n.noBills,
        actionLabel: l10n.newBill,
        onAction: () => _openForm(context),
      );
    }
    return RefreshIndicator(
      onRefresh: () => pager.refresh(),
      child: ListView.separated(
        controller: _scrollController,
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
    await context.push('/bill/${bill.id}');
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
    final customerLabel = bill.customerShopName ?? l10n.walkIn;

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
