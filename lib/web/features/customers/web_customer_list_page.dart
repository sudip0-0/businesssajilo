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

  void _selectCustomer(Customer customer) {
    context.go('${_webRolePrefix(context)}/customers/${customer.id}');
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
                onChanged: _onQueryChanged,
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
    final items = pager.items;
    if (items.isEmpty) {
      final searching = _query.isNotEmpty;
      return WebEmptyState(
        message: searching ? l10n.noSearchResults : l10n.noCustomers,
        icon: PhosphorIconsRegular.storefront,
        actionLabel: searching
            ? l10n.clearSearch
            : (widget.canEdit ? l10n.addCustomer : null),
        onAction: searching
            ? () {
                setState(() => _query = '');
                pager.refresh();
              }
            : (widget.canEdit
                  ? () => context.go('${_webRolePrefix(context)}/customers/new')
                  : null),
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

    return WebHoverableRow(
      selected: selected,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: WebPalette.navyWash,
              child: Text(
                customer.shopName.isNotEmpty
                    ? customer.shopName[0].toUpperCase()
                    : '?',
                style: const TextStyle(color: WebPalette.navy),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.shopName,
                    style: theme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
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
                  color: WebPalette.navy,
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
                    color: due > 0 ? WebPalette.danger : WebPalette.success,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    formatNpr(Paisa(due), showPaisa: false),
                    style: theme.titleSmall?.copyWith(
                      color: due > 0 ? WebPalette.danger : WebPalette.success,
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
