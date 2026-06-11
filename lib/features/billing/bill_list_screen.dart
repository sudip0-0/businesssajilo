import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initPager());
  }

  void _initPager() {
    _pager = PaginatedListState<Bill>(
      loadPage: (offset, limit) => ref
          .read(billsRepositoryProvider)
          .list(offset: offset, limit: limit),
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

  List<Bill> get _filtered {
    final items = _pager?.items ?? [];
    return items.where((b) {
      if (_query.isEmpty) return true;
      return b.billNo.toLowerCase().contains(_query) ||
          (b.customerShopName?.toLowerCase().contains(_query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pager = _pager;

    final listPane = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            decoration: InputDecoration(
              hintText: l10n.filterBills,
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
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

  Widget _buildListBody(AppLocalizations l10n, PaginatedListState<Bill>? pager) {
    if (pager == null || pager.initialLoading) {
      return const ListSkeleton();
    }
    if (pager.error != null && pager.items.isEmpty) {
      return ErrorState(onRetry: () => pager.refresh());
    }
    final filtered = _filtered;
    if (filtered.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        message: l10n.noBills,
        actionLabel: l10n.newBill,
        onAction: () => _openForm(context),
      );
    }
    return ListView.separated(
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
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BillDetailScreen(billId: bill.id),
      ),
    );
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

    return ListTile(
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
              child: const Icon(Icons.schedule, size: 14, color: BsColors.accent),
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
            formatNpr(Paisa(bill.grandTotal), showPaisa: false),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          BillStatusChip(bill.status),
        ],
      ),
    );
  }
}
