import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/ui/adaptive_sheet.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/list_skeleton.dart';
import '../../core/ui/paginated_list_state.dart';
import '../../core/ui/stock_badge.dart';
import '../../core/utils/stock_status.dart';
import '../../data/repositories/products_repository.dart';
import '../../domain/models/product.dart';
import 'product_form_screen.dart';
import 'product_image.dart';
import 'providers.dart';
import 'reorder_low_stock_sheet.dart';

enum _StockFilter { all, low, out, inStock }

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
  _StockFilter _stockFilter = _StockFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initPager());
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

  void _onQueryChanged(String value) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(_searchDebounce, () {
      if (!mounted) return;
      setState(() => _query = value.trim());
      _pager?.refresh();
    });
  }

  void _setStockFilter(_StockFilter filter) {
    if (_stockFilter == filter) return;
    setState(() => _stockFilter = filter);
    if (filter != _StockFilter.all) {
      // Status filters are applied client-side, so make sure the whole
      // catalog is loaded before showing a filtered list.
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadAllForFilter());
    }
  }

  Future<void> _loadAllForFilter() async {
    final pager = _pager;
    if (pager == null) return;
    while (pager.hasMore && !pager.loading) {
      await pager.loadMore();
    }
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
    _scrollController.dispose();
    super.dispose();
  }

  List<Product> get _filtered {
    final items = _pager?.items ?? [];
    return switch (_stockFilter) {
      _StockFilter.all => items,
      _StockFilter.low =>
        items.where((p) => stockLevelFor(p) == StockLevel.lowStock).toList(),
      _StockFilter.out =>
        items.where((p) => stockLevelFor(p) == StockLevel.outOfStock).toList(),
      _StockFilter.inStock =>
        items.where((p) => stockLevelFor(p) == StockLevel.inStock).toList(),
    };
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
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final (filter, label) in [
                  (_StockFilter.all, l10n.allStock),
                  (_StockFilter.low, l10n.stockFilterLow),
                  (_StockFilter.out, l10n.stockFilterOut),
                  (_StockFilter.inStock, l10n.stockFilterIn),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(label),
                      selected: _stockFilter == filter,
                      onSelected: (_) => _setStockFilter(filter),
                    ),
                  ),
              ],
            ),
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
      final filtering = _stockFilter != _StockFilter.all;
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
          final subtitleParts = [
            if (product.sku != null && product.sku!.isNotEmpty) product.sku!,
            if (!product.isActive) l10n.inactive,
          ];
          return Semantics(
            button: true,
            label: [
              product.name,
              ...subtitleParts,
              '${product.stockCached}',
            ].join(', '),
            child: ListTile(
              leading: ProductImage(storagePath: product.imageUrl),
              title: Text(product.name),
              subtitle: Text(subtitleParts.join(' · ')),
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
