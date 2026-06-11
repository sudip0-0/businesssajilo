import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/list_skeleton.dart';
import '../../core/ui/paginated_list_state.dart';
import '../../core/ui/stock_badge.dart';
import '../../data/repositories/categories_repository.dart';
import '../../data/repositories/products_repository.dart';
import '../../domain/models/category.dart';
import '../../domain/models/product.dart';
import 'category_list_screen.dart';
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
  String? _categoryId;
  PaginatedListState<Product>? _pager;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initPager());
  }

  void _initPager() {
    _pager = PaginatedListState<Product>(
      loadPage: (offset, limit) => ref
          .read(productsRepositoryProvider)
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

  List<Product> get _filtered {
    final items = _pager?.items ?? [];
    return items.where((p) {
      final matchesQuery = _query.isEmpty ||
          p.name.toLowerCase().contains(_query.toLowerCase()) ||
          (p.sku?.toLowerCase().contains(_query.toLowerCase()) ?? false);
      final matchesCategory = _categoryId == null || p.categoryId == _categoryId;
      return matchesQuery && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final categoriesAsync = ref.watch(
      FutureProvider.autoDispose((ref) => ref.watch(categoriesRepositoryProvider).list()),
    );
    final pager = _pager;

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
        categoriesAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
          data: (categories) => _CategoryChips(
            categories: categories,
            selectedId: _categoryId,
            onSelected: (id) => setState(() => _categoryId = id),
          ),
        ),
        if (widget.canEdit)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CategoryListScreen()),
                );
                await _pager?.refresh();
              },
              icon: const Icon(Icons.category_outlined),
              label: Text(l10n.categories),
            ),
          ),
        Expanded(child: _buildListBody(l10n, pager)),
      ],
    );
  }

  Widget _buildListBody(AppLocalizations l10n, PaginatedListState<Product>? pager) {
    if (pager == null || pager.initialLoading) {
      return const ListSkeleton();
    }
    if (pager.error != null && pager.items.isEmpty) {
      return ErrorState(onRetry: () => pager.refresh());
    }
    final filtered = _filtered;
    if (filtered.isEmpty) {
      return EmptyState(
        icon: Icons.inventory_2_outlined,
        message: l10n.emptyNoProducts,
        actionLabel: widget.canEdit ? l10n.emptyAddFirstProduct : null,
        onAction: widget.canEdit ? () => _openForm(context, null) : null,
      );
    }
    return ListView.separated(
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
              if (product.categoryName != null) product.categoryName,
              if (product.sku != null) product.sku,
            ].whereType<String>().join(' · '),
          ),
          trailing: StockBadge(product: product),
          onTap: () => _openDetail(context, product),
        );
      },
    );
  }

  Future<void> _openForm(BuildContext context, Product? product) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ProductFormScreen(product: product),
      ),
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

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (categories.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            label: Text(l10n.allCategories),
            selected: selectedId == null,
            onSelected: (_) => onSelected(null),
          ),
          const SizedBox(width: 8),
          ...categories.map(
            (c) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(c.name),
                selected: selectedId == c.id,
                onSelected: (_) => onSelected(c.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
