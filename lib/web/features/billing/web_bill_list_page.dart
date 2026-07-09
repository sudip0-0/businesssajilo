import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/bill_status_chip.dart';
import '../../../core/ui/paginated_list_state.dart';
import '../../../core/utils/money.dart';
import '../../../data/repositories/bills_repository.dart';
import '../../../domain/models/bill.dart';
import '../../../features/billing/bill_detail_screen.dart';
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

class WebBillListPage extends ConsumerStatefulWidget {
  const WebBillListPage({super.key, this.selectedBillId});

  final String? selectedBillId;

  @override
  ConsumerState<WebBillListPage> createState() => _WebBillListPageState();
}

class _WebBillListPageState extends ConsumerState<WebBillListPage> {
  String _query = '';
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

  void _selectBill(Bill bill) {
    context.go('${_webRolePrefix(context)}/billing/${bill.id}');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final prefix = _webRolePrefix(context);
    final selectedId = widget.selectedBillId;
    final pager = _pager;

    return WebPageScaffold(
      title: l10n.billing,
      actions: [
        FilledButton.icon(
          onPressed: () => context.push('$prefix/billing/new'),
          icon: Icon(PhosphorIconsRegular.plus),
          label: Text(l10n.newBill),
        ),
      ],
      body: WebMasterDetail(
        hasSelection: selectedId != null,
        list: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: WebSearchField(
                hint: l10n.filterBills,
                onChanged: _onQueryChanged,
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
    if (_query.isNotEmpty) {
      if (_searching && _searchResults == null) {
        return const WebListSkeleton();
      }
      final results = _searchResults ?? const <Bill>[];
      if (results.isEmpty) {
        return WebEmptyState(
          message: l10n.noSearchResults,
          icon: PhosphorIconsRegular.receipt,
          actionLabel: l10n.clearSearch,
          onAction: () => setState(() {
            _query = '';
            _searchResults = null;
          }),
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
    if (pager.items.isEmpty) {
      return WebEmptyState(
        message: l10n.noBills,
        icon: PhosphorIconsRegular.receipt,
        actionLabel: l10n.newBill,
        onAction: () => context.push('${_webRolePrefix(context)}/billing/new'),
      );
    }

    return RefreshIndicator(
      onRefresh: () => pager.refresh(),
      child: ListView.separated(
        controller: _scrollController,
        itemCount: pager.items.length + (pager.hasMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 0),
        itemBuilder: (context, index) {
          if (index >= pager.items.length) {
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
          final bill = pager.items[index];
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
    final customerLabel = bill.customerShopName ?? l10n.walkIn;

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
              color: bill.pendingSync ? BsColors.accent : BsColors.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bill.billNo,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    customerLabel,
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
