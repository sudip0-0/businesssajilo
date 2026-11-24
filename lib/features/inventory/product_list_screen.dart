import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/preferences/saved_filters_store.dart';
import '../../core/ui/adaptive_sheet.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/list_skeleton.dart';
import '../../core/ui/paginated_list_state.dart';
import '../../core/ui/reset_filters_button.dart';
import '../../core/ui/stock_badge.dart';
import '../../data/repositories/products_repository.dart';
import '../../domain/enums.dart';
import '../../domain/models/product.dart';
import '../auth/providers/filter_scope_provider.dart';
import 'product_form_screen.dart';
import 'product_image.dart';
import 'product_import_sheet.dart';
import 'providers.dart';
import 'reorder_low_stock_sheet.dart';
import 'stock_count_screen.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({
    super.key,
    required this.canEdit,
    this.canManageStock = false,
  });

  final bool canEdit;
  final bool canManageStock;

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  static const _searchDebounce = Duration(milliseconds: 300);

  String _query = '';
  Timer? _searchDebounceTimer;
  PaginatedListState<Product>? _pager;
  final _scrollController = ScrollController();
  bool _showInactive = false;
  ProductStockFilter _stockFilter = ProductStockFilter.all;
  InventorySortField _sortField = InventorySortField.name;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final scope = ref.read(currentFilterScopeProvider);
    final saved = await ref
        .read(savedFiltersStoreProvider)
        .loadInventory(scope, canEdit: widget.canEdit);
    if (!mounted) return;
    setState(() {
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

  void _onQueryChanged(String value) {
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

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  List<Product> get _filtered {
    final filtered = List<Product>.from(_pager?.items ?? []);
    filtered.sort((a, b) {
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
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pager = _pager;
    final lowStockCount = ref.watch(lowStockCountProvider).value ?? 0;

    ref.listen<int>(inventoryRevisionProvider, (prev, next) {
      if (prev != next) {
        _pager?.refresh();
      }
    });

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            decoration: InputDecoration(
              hintText: l10n.filterProducts,
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
                    if (_filterState.activeCount > 0)
                      ResetFiltersButton(
                        activeCount: _filterState.activeCount,
                        onReset: _resetFilters,
                      ),
                  ],
                ),
              ),
              PopupMenuButton<InventorySortField>(
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
              ),
              if (widget.canManageStock)
                IconButton(
                  tooltip: l10n.stockCount,
                  onPressed: _openStockCount,
                  icon: const Icon(Icons.fact_check_outlined),
                ),
              if (widget.canEdit)
                IconButton(
                  tooltip: l10n.importFromExcel,
                  onPressed: () async {
                    final imported = await showProductImportSheet(context);
                    if (imported == true && mounted) {
                      await _pager?.refresh();
                    }
                  },
                  icon: const Icon(Icons.upload_file_outlined),
                ),
            ],
          ),
        ),
        if (lowStockCount > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: _openReorder,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text('${l10n.reorder} · $lowStockCount'),
              ),
            ),
          ),
        if (widget.canEdit)
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            title: Text(_showInactive ? l10n.hideInactive : l10n.showInactive),
            value: _showInactive,
            onChanged: _setShowInactive,
          ),
        Expanded(child: _buildListBody(l10n, pager)),
      ],
    );
  }

  Future<void> _openStockCount() async {
    final reconciled = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const StockCountScreen()),
    );
    if (reconciled == true && mounted) {
      ref.invalidate(lowStockCountProvider);
      ref.invalidate(lowStockProductsProvider);
      await _pager?.refresh();
    }
  }

  Future<void> _openReorder() async {
    final saved = await showAdaptiveSheet<bool>(
      context: context,
      title: AppLocalizations.of(context).reorder,
      child: const ReorderLowStockSheet(),
    );
    if (saved == true) {
      ref.invalidate(lowStockCountProvider);
      ref.invalidate(lowStockProductsProvider);
      await _pager?.refresh();
    }
  }

  Widget _buildListBody(
    AppLocalizations l10n,
    PaginatedListState<Product>? pager,
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
      final filtering = _stockFilter != ProductStockFilter.all;
      return EmptyState(
        icon: Icons.inventory_2_outlined,
        message: searching
            ? l10n.noSearchResults
            : (filtering ? l10n.noMatchingResults : l10n.emptyNoProducts),
        actionLabel: searching
            ? l10n.clearSearch
            : (widget.canEdit ? l10n.emptyAddFirstProduct : null),
        onAction: searching
            ? () => setState(() => _query = '')
            : (widget.canEdit ? () => _openForm(context, null) : null),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        await pager.refresh();
        ref.invalidate(lowStockCountProvider);
      },
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
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
          final product = filtered[index];
          final inactiveLabel = product.isActive ? null : l10n.inactive;
          return Semantics(
            button: true,
            label: [
              product.name,
              ?inactiveLabel,
              '${product.stockCached}',
            ].join(', '),
            child: ListTile(
              leading: ProductImage(storagePath: product.imageUrl),
              title: Text(product.name),
              subtitle: inactiveLabel == null ? null : Text(inactiveLabel),
              trailing: StockBadge(product: product),
              onTap: () => _openDetail(context, product),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openForm(BuildContext context, Product? product) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)),
    );
    if (saved == true) await _pager?.refresh();
  }

  Future<void> _openDetail(BuildContext context, Product product) async {
    final changed = await context.push<bool>('/product/${product.id}');
    if (changed == true) {
      await _pager?.refresh();
      ref.invalidate(lowStockCountProvider);
    }
  }
}
