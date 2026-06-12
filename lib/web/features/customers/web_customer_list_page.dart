import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/paginated_list_state.dart';
import '../../../core/utils/money.dart';
import '../../../data/repositories/customers_repository.dart';
import '../../../domain/models/customer.dart';
import '../../../features/customers/add_customer_sheet.dart';
import '../../../features/customers/customer_detail_screen.dart';
import '../../../features/customers/providers.dart';
import '../../ui/web_sheet_bridge.dart';
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

class _WebCustomerListPageState extends ConsumerState<WebCustomerListPage> {
  String _query = '';
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

  void _selectCustomer(Customer customer) {
    context.go('${_webRolePrefix(context)}/customers/${customer.id}');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selectedId = widget.selectedCustomerId;
    final pager = _pager;

    return WebPageScaffold(
      title: l10n.customers,
      actions: widget.canEdit
          ? [
              FilledButton.icon(
                onPressed: () async {
                  final created = await showAdaptiveSheet<bool>(
                    context: context,
                    title: l10n.addCustomer,
                    child: const AddCustomerSheet(embedded: true),
                  );
                  if (created == true) {
                    await _pager?.refresh();
                    ref.invalidate(customerListProvider);
                    ref.invalidate(totalDuesProvider);
                    setState(() {});
                  }
                },
                icon: Icon(PhosphorIconsRegular.userPlus),
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
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: WebSearchField(
                hint: l10n.filterCustomers,
                onChanged: (v) =>
                    setState(() => _query = v.trim().toLowerCase()),
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
        actionLabel: l10n.retrySync,
        onAction: () => pager.refresh(),
        icon: PhosphorIconsRegular.warning,
      );
    }
    final filtered = _filtered;
    if (filtered.isEmpty) {
      return WebEmptyState(
        message: l10n.noCustomers,
        icon: PhosphorIconsRegular.storefront,
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
          final customer = filtered[index];
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

    return WebHoverableRow(
      selected: selected,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: BsColors.primary.withValues(alpha: 0.12),
              child: Text(
                customer.shopName.isNotEmpty
                    ? customer.shopName[0].toUpperCase()
                    : '?',
                style: const TextStyle(color: BsColors.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.shopName,
                    style: theme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (customer.contactName != null || customer.phone != null)
                    Text(
                      [
                        if (customer.contactName != null) customer.contactName!,
                        if (customer.phone != null) customer.phone!,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                ],
              ),
            ),
            if (due < 0)
              Text(
                '${l10n.creditBalance} ${formatNpr(Paisa(-due), showPaisa: false)}',
                style: theme.labelSmall?.copyWith(
                  color: BsColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              Row(
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
          ],
        ),
      ),
    );
  }
}
