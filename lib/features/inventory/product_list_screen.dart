import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/list_skeleton.dart';
import '../../core/ui/paginated_list_state.dart';
import '../../core/ui/stock_badge.dart';
import '../../data/repositories/products_repository.dart';
import '../../domain/models/product.dart';
import 'product_detail_screen.dart';
import 'product_form_screen.dart';
import 'product_image.dart';
import 'providers.dart';

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
  String _query = '';
  PaginatedListState<Product>? _pager;
  final _scrollController = ScrollController();
  bool _showInactive = false;

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
          ),
      onChanged: () {
        if (mounted) setState(() {});
      },
    )..attachScrollController(_scrollController);
    _pager!.refresh().then((_) {
      if (mounted) setState(() {});
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
    _scrollController.dispose();
    super.dispose();
  }

  List<Product> get _filtered {
    final items = _pager?.items ?? [];
    return items.where((p) {
      return _query.isEmpty ||
          p.name.toLowerCase().contains(_query.toLowerCase()) ||
          (p.sku?.toLowerCase().contains(_query.toLowerCase()) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pager = _pager;

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
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        if (widget.canEdit)
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            title: Text(
              _showInactive ? l10n.hideInactive : l10n.showInactive,
            ),
            value: _showInactive,
            onChanged: _setShowInactive,
          ),
        Expanded(child: _buildListBody(l10n, pager)),
      ],
    );
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
      return EmptyState(
        icon: Icons.inventory_2_outlined,
        message: searching ? l10n.noSearchResults : l10n.emptyNoProducts,
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
          return ListTile(
            leading: ProductImage(storagePath: product.imageUrl),
            title: Text(product.name),
            subtitle: Text(
              [
                if (product.sku != null && product.sku!.isNotEmpty) product.sku!,
                if (!product.isActive) l10n.inactive,
              ].join(' · '),
            ),
            trailing: StockBadge(product: product),
            onTap: () => _openDetail(context, product),
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
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          productId: product.id,
          canManageStock: widget.canManageStock,
          canEditProduct: widget.canEdit,
        ),
      ),
    );
    if (changed == true) {
      await _pager?.refresh();
      ref.invalidate(lowStockCountProvider);
    }
  }
}
