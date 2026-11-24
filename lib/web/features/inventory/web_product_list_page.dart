import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/preferences/saved_filters_store.dart';
import '../../../core/ui/paginated_list_state.dart';
import '../../../core/ui/reset_filters_button.dart';
import '../../../core/ui/stock_badge.dart';
import '../../../core/utils/money.dart';
import '../../../data/repositories/products_repository.dart';
import '../../../domain/enums.dart';
import '../../../domain/models/product.dart';
import '../../../core/ui/adaptive_sheet.dart';
import '../../../features/auth/providers/filter_scope_provider.dart';
import '../../../features/inventory/product_detail_screen.dart';
import '../../../features/inventory/product_import_sheet.dart';
import '../../../features/inventory/providers.dart';
import '../../../features/inventory/reorder_low_stock_sheet.dart';
import '../../../features/inventory/stock_in_picker_sheet.dart';
import '../../layout/web_master_detail.dart';
import '../../theme/web_palette.dart';
import '../../ui/web_data_table.dart';
import '../../ui/web_empty_state.dart';
import '../../ui/web_search_field.dart';
import '../../ui/web_skeleton.dart';
import '../web_page_scaffold.dart';
import 'web_stock_count_dialog.dart';

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

class _WebProductListPageState extends ConsumerState<WebProductListPage> {
  static const _searchDebounce = Duration(milliseconds: 300);

  String _query = '';
  Timer? _searchDebounceTimer;
  PaginatedListState<Product>? _pager;
  final _scrollController = ScrollController();
  late final TextEditingController _searchController;
  bool _showInactive = false;
  ProductStockFilter _stockFilter = ProductStockFilter.all;
  InventorySortField _sortField = InventorySortField.name;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final initialQ = GoRouterState.of(context).uri.queryParameters['q'] ?? '';
    final scope = ref.read(currentFilterScopeProvider);
    final saved = await ref
        .read(savedFiltersStoreProvider)
        .loadInventory(scope, canEdit: widget.canEdit);
    if (!mounted) return;
    setState(() {
      if (initialQ.isNotEmpty) {
        _query = initialQ;
        _searchController.text = initialQ;
      }
      _stockFilter = saved.stockFilter;
      _showInactive = widget.canEdit && saved.showInactive;
      _sortField = saved.sortField;
      _sortAscending = saved.sortAscending;
    });
    _initPager();
  }

  InventoryListFilterState get _filterState => InventoryListFilterState(
    stockFilter: _stockFilter,
    showInactive: widget.canEdit && _showInactive,
    sortField: _sortField,
    sortAscending: _sortAscending,
  );

  void _persistFilters() {
    final scope = ref.read(currentFilterScopeProvider);
    unawaited(
      ref.read(savedFiltersStoreProvider).saveInventory(scope, _filterState),
    );
  }

  void _resetFilters() {
    if (_filterState.isDefault) return;
    setState(() {
      _stockFilter = ProductStockFilter.all;
      _showInactive = false;
      _sortField = InventorySortField.name;
      _sortAscending = true;
    });
    _persistFilters();
    _pager?.refresh();
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
            stockFilter: _stockFilter,
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

  void _setStockFilter(ProductStockFilter filter) {
    if (_stockFilter == filter) return;
    setState(() => _stockFilter = filter);
    _persistFilters();
    _pager?.refresh();
  }

  Future<void> _setShowInactive(bool value) async {
    if (_showInactive == value) return;
    setState(() => _showInactive = value);
    _persistFilters();
    await _pager?.refresh();
    if (mounted) setState(() {});
  }

  Future<void> _openStockCount() async {
    final reconciled = await showWebStockCountDialog(context);
    if (reconciled == true && mounted) {
      bumpInventoryRevision(ref);
      ref.invalidate(lowStockCountProvider);
      ref.invalidate(lowStockProductsProvider);
      await _pager?.refresh();
    }
  }

  Future<void> _openStockIn() async {
    final l10n = AppLocalizations.of(context);
    final saved = await showAdaptiveSheet<bool>(
      context: context,
      title: l10n.stockIn,
      child: const StockInPickerSheet(),
    );
    if (saved == true && mounted) {
      bumpInventoryRevision(ref);
      ref.invalidate(lowStockCountProvider);
      await _pager?.refresh();
    }
  }

  Future<void> _openReorder() async {
    final saved = await showAdaptiveSheet<bool>(
      context: context,
      title: AppLocalizations.of(context).reorder,
      child: const ReorderLowStockSheet(),
    );
    if (saved == true && mounted) {
      ref.invalidate(lowStockCountProvider);
      ref.invalidate(lowStockProductsProvider);
      bumpInventoryRevision(ref);
      await _pager?.refresh();
    }
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
    return PopupMenuButton<InventorySortField>(
      initialValue: _sortField,
      tooltip: l10n.sortBy,
      icon: Icon(
        _sortAscending
            ? PhosphorIconsRegular.arrowUp
            : PhosphorIconsRegular.arrowDown,
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
          value: InventorySortField.name,
          child: Text(
            l10n.sortName,
            style: TextStyle(
              fontWeight: _sortField == InventorySortField.name
                  ? FontWeight.bold
                  : null,
            ),
          ),
        ),
        PopupMenuItem(
          value: InventorySortField.quantity,
          child: Text(
            l10n.sortQuantity,
            style: TextStyle(
              fontWeight: _sortField == InventorySortField.quantity
                  ? FontWeight.bold
                  : null,
            ),
          ),
        ),
        PopupMenuItem(
          value: InventorySortField.price,
          child: Text(
            l10n.sortPrice,
            style: TextStyle(
              fontWeight: _sortField == InventorySortField.price
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
    final lowStockCount = ref.watch(lowStockCountProvider).value ?? 0;
    final activeFilterCount = _filterState.activeCount;

    ref.listen<int>(inventoryRevisionProvider, (prev, next) {
      if (prev != next) {
        _pager?.refresh();
      }
    });

    return WebPageScaffold(
      title: l10n.inventory,
      actions: [
        if (widget.canManageStock) ...[
          OutlinedButton.icon(
            onPressed: _openStockCount,
            icon: const Icon(PhosphorIconsRegular.clipboardText),
            label: Text(l10n.stockCount),
          ),
          OutlinedButton.icon(
            onPressed: _openStockIn,
            icon: const Icon(PhosphorIconsRegular.package),
            label: Text(l10n.stockIn),
          ),
        ],
        if (widget.canEdit) ...[
          Tooltip(
            message: l10n.importFromExcel,
            child: IconButton.outlined(
              onPressed: () async {
                final imported = await showProductImportSheet(context);
                if (imported == true && mounted) {
                  await _pager?.refresh();
                }
              },
              icon: const Icon(PhosphorIconsRegular.uploadSimple),
            ),
          ),
          FilledButton.icon(
            onPressed: () => context.push('${_inventoryListBase(context)}/new'),
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
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final (filter, label) in [
                    (ProductStockFilter.all, l10n.allStock),
                    (ProductStockFilter.low, l10n.stockFilterLow),
                    (ProductStockFilter.out, l10n.stockFilterOut),
                    (ProductStockFilter.inStock, l10n.stockFilterIn),
                  ])
                    FilterChip(
                      label: Text(label),
                      selected: _stockFilter == filter,
                      onSelected: (_) => _setStockFilter(filter),
                    ),
                  if (widget.canEdit)
                    FilterChip(
                      label: Text(
                        _showInactive ? l10n.hideInactive : l10n.showInactive,
                      ),
                      selected: _showInactive,
                      onSelected: _setShowInactive,
                    ),
                  if (activeFilterCount > 0)
                    ResetFiltersButton(
                      activeCount: activeFilterCount,
                      onReset: _resetFilters,
                    ),
                ],
              ),
            ),
            if (lowStockCount > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: _openReorder,
                    icon: const Icon(PhosphorIconsRegular.arrowsClockwise),
                    label: Text('${l10n.reorder} · $lowStockCount'),
                  ),
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
                onEditProduct: (product) => context.push(
                  '${_inventoryListBase(context)}/${product.id}/edit',
                ),
              ),
      ),
    );
  }

  List<Product> _sorted(List<Product> items) {
    final sorted = items.where((p) => p.isActive == !_showInactive).toList();
    sorted.sort((a, b) {
      final cmp = switch (_sortField) {
        InventorySortField.name => a.name.toLowerCase().compareTo(
          b.name.toLowerCase(),
        ),
        InventorySortField.quantity => a.stockCached.compareTo(b.stockCached),
        InventorySortField.price => a.referencePrice.compareTo(
          b.referencePrice,
        ),
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
