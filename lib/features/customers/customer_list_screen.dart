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
import '../../domain/models/customer.dart';
import '../../core/ui/adaptive_sheet.dart';
import 'add_customer_sheet.dart';
import 'customer_detail_screen.dart';
import 'providers.dart';

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
  String _query = '';
  String? _selectedCustomerId;
  PaginatedListState<Customer>? _pager;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initPager());
  }

  void _initPager() {
    _pager = PaginatedListState<Customer>(
      loadPage: (offset, limit) => ref
          .read(customersRepositoryProvider)
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

  List<Customer> get _filtered {
    final items = _pager?.items ?? [];
    return items.where((c) {
      if (_query.isEmpty) return true;
      return c.shopName.toLowerCase().contains(_query) ||
          (c.contactName?.toLowerCase().contains(_query) ?? false) ||
          (c.phone?.contains(_query) ?? false);
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
              hintText: l10n.filterCustomers,
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
    final filtered = _filtered;
    if (filtered.isEmpty) {
      final searching = _query.trim().isNotEmpty;
      return EmptyState(
        icon: Icons.storefront_outlined,
        message: searching ? l10n.noSearchResults : l10n.noCustomers,
        actionLabel: searching
            ? l10n.clearSearch
            : (widget.canEdit ? l10n.addCustomer : null),
        onAction: searching
            ? () => setState(() => _query = '')
            : (widget.canEdit ? () => _openAddCustomer(context) : null),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        await pager.refresh();
        ref.invalidate(totalDuesProvider);
      },
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
          final customer = filtered[index];
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
      await _pager?.refresh();
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

    return ListTile(
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
      subtitle: Text(
        [
          if (customer.contactName != null) customer.contactName!,
          if (customer.phone != null) customer.phone!,
        ].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
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
                  ),
                ),
              ],
            ),
    );
  }
}
