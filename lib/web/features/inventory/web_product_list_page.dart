import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/ui/paginated_list_state.dart';
import '../../../core/ui/stock_badge.dart';
import '../../../core/utils/money.dart';
import '../../../data/repositories/products_repository.dart';
import '../../../domain/models/product.dart';
import '../../../features/inventory/product_detail_screen.dart';
import '../../../features/inventory/product_import_sheet.dart';
import '../../../features/inventory/providers.dart';
import '../../layout/web_master_detail.dart';
import '../../theme/web_palette.dart';
import '../../ui/web_data_table.dart';
import '../../ui/web_empty_state.dart';
import '../../ui/web_search_field.dart';
import '../../ui/web_skeleton.dart';
import '../web_page_scaffold.dart';

/// Base path for the product list under the current role shell.
/// Owner: `/owner/inventory`; sales/warehouse: `/sales/stock`, `/warehouse/stock`.
String _inventoryListBase(BuildContext context) {
  final segments = GoRouterState.of(context).uri.pathSegments;
  if (segments.length >= 2) {
    return '/${segments[0]}/${segments[1]}';
  }
  if (segments.isEmpty) return '';
  return '/${segments.first}';
}

class WebProductListPage extends ConsumerStatefulWidget {
  const WebProductListPage({
    super.key,
    this.selectedProductId,
    this.canEdit = false,
    this.canManageStock = false,
  });

  final String? selectedProductId;
  final bool canEdit;
  final bool canManageStock;

  @override
  ConsumerState<WebProductListPage> createState() => _WebProductListPageState();
}

enum _SortField { name, quantity, price }

class _WebProductListPageState extends ConsumerState<WebProductListPage> {
  static const _searchDebounce = Duration(milliseconds: 300);

  String _query = '';
  Timer? _searchDebounceTimer;
  PaginatedListState<Product>? _pager;
  final _scrollController = ScrollController();
  late final TextEditingController _searchController;
  bool _showInactive = false;
  _SortField _sortField = _SortField.name;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialQ = GoRouterState.of(context).uri.queryParameters['q'] ?? '';
      if (initialQ.isNotEmpty) {
        _query = initialQ;
        _searchController.text = initialQ;
      }
      _initPager();
    });
  }

  void _initPager() {
    _pager = PaginatedListState<Product>(
      loadPage: (offset, limit) => ref
          .read(productsRepositoryProvider)
          .list(
            activeOnly: !_showInactive,
            offset: offset,
            limit: limit,
            query: _query.trim().isEmpty ? null : _query.trim(),
          ),
      onChanged: () {
        if (mounted) setState(() {});
      },
    )..attachScrollController(_scrollController);
    _pager!.refresh().then((_) {
      if (mounted) setState(() {});
    });
  }

  void _refreshForQuery(String value) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(_searchDebounce, () {
      if (!mounted) return;
      setState(() => _query = value.trim());
      _pager?.refresh();
    });
  }

  Future<void> _setShowInactive(bool value) async {
    if (_showInactive == value) return;
    setState(() => _showInactive = value);
    await _pager?.refresh();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final q = GoRouterState.of(context).uri.queryParameters['q'] ?? '';
    if (q != _query) {
      _query = q;
      if (_searchController.text != q) {
        _searchController.text = q;
      }
      _pager?.refresh();
    }
  }

  void _openProduct(Product product) {
    context.go('${_inventoryListBase(context)}/${product.id}');
  }

  Widget _buildSortControl(AppLocalizations l10n) {
    return PopupMenuButton<_SortField>(
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
          value: _SortField.name,
          child: Text(
            l10n.sortName,
            style: TextStyle(
              fontWeight: _sortField == _SortField.name
                  ? FontWeight.bold
                  : null,
            ),
          ),
        ),
        PopupMenuItem(
          value: _SortField.quantity,
          child: Text(
            l10n.sortQuantity,
            style: TextStyle(
              fontWeight: _sortField == _SortField.quantity
                  ? FontWeight.bold
                  : null,
            ),
          ),
        ),
        PopupMenuItem(
          value: _SortField.price,
          child: Text(
            l10n.sortPrice,
            style: TextStyle(
              fontWeight: _sortField == _SortField.price
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
    final pager = _pager;
    final selectedId = widget.selectedProductId;

    ref.listen<int>(inventoryRevisionProvider, (prev, next) {
      if (prev != next) {
        _pager?.refresh();
      }
    });

    return WebPageScaffold(
      title: l10n.inventory,
      actions: [
        if (widget.canEdit) ...[
          FilterChip(
            label: Text(_showInactive ? l10n.hideInactive : l10n.showInactive),
            selected: _showInactive,
            onSelected: _setShowInactive,
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () async {
              final imported = await showProductImportSheet(context);
              if (imported == true && mounted) {
                await _pager?.refresh();
              }
            },
            icon: const Icon(PhosphorIconsRegular.uploadSimple),
            label: Text(l10n.importFromExcel),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () =>
                context.push('${_inventoryListBase(context)}/new'),
            icon: const Icon(PhosphorIconsRegular.plus),
            label: Text(l10n.addProduct),
          ),
        ],
      ],
      body: WebMasterDetail(
        hasSelection: selectedId != null,
        list: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: WebSearchField(
                      hint: l10n.filterProducts,
                      controller: _searchController,
                      onChanged: _refreshForQuery,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildSortControl(l10n),
                ],
              ),
            ),
            Expanded(child: _buildListBody(l10n, pager)),
          ],
        ),
        detail: selectedId == null
            ? null
            : ProductDetailScreen(
                productId: selectedId,
                canEditProduct: widget.canEdit,
                canManageStock: widget.canManageStock,
                embedded: true,
              ),
      ),
    );
  }

  List<Product> _sorted(List<Product> items) {
    final sorted = List<Product>.from(items);
    sorted.sort((a, b) {
      final cmp = switch (_sortField) {
        _SortField.name => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        _SortField.quantity => a.stockCached.compareTo(b.stockCached),
        _SortField.price => a.referencePrice.compareTo(b.referencePrice),
      };
      return _sortAscending ? cmp : -cmp;
    });
    return sorted;
  }

  Widget _buildListBody(
    AppLocalizations l10n,
    PaginatedListState<Product>? pager,
  ) {
    final loading = pager == null || pager.initialLoading;

    if (loading) {
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
      final searching = _query.isNotEmpty;
      return WebEmptyState(
        message: searching ? l10n.noSearchResults : l10n.emptyNoProducts,
        icon: PhosphorIconsRegular.package,
        actionLabel: searching
            ? l10n.clearSearch
            : (widget.canEdit ? l10n.emptyAddFirstProduct : null),
        onAction: searching
            ? () {
                setState(() {
                  _query = '';
                  _searchController.clear();
                });
                _pager?.refresh();
              }
            : (widget.canEdit
                  ? () => context.push('${_inventoryListBase(context)}/new')
                  : null),
      );
    }

    final sorted = _sorted(pager.items);

    return RefreshIndicator(
      onRefresh: () async {
        await pager.refresh();
        ref.invalidate(lowStockCountProvider);
      },
      child: ListView.separated(
        controller: _scrollController,
        itemCount: sorted.length + (pager.hasMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 0),
        itemBuilder: (context, index) {
          if (index >= sorted.length) {
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

          final product = sorted[index];
          return _ProductRow(
            product: product,
            selected: product.id == widget.selectedProductId,
            onTap: () => _openProduct(product),
          );
        },
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.product,
    required this.onTap,
    this.selected = false,
  });

  final Product product;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sku = product.sku;
    final subtitle = [
      if (sku != null && sku.isNotEmpty) sku,
      if (!product.isActive) l10n.inactive,
    ].join(' · ');

    return WebHoverableRow(
      selected: selected,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(
              PhosphorIconsRegular.package,
              color: WebPalette.navy,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatNpr(Paisa(product.referencePrice), showPaisa: false),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                StockBadge(product: product, compact: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
