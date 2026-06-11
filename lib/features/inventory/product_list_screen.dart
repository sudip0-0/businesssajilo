import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/stock_badge.dart';
import '../../data/repositories/categories_repository.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final productsAsync = ref.watch(productListProvider);
    final categoriesAsync = ref.watch(
      FutureProvider.autoDispose((ref) => ref.watch(categoriesRepositoryProvider).list()),
    );

    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (products) {
        final filtered = products.where((p) {
          final matchesQuery = _query.isEmpty ||
              p.name.toLowerCase().contains(_query.toLowerCase()) ||
              (p.sku?.toLowerCase().contains(_query.toLowerCase()) ?? false);
          final matchesCategory =
              _categoryId == null || p.categoryId == _categoryId;
          return matchesQuery && matchesCategory;
        }).toList();

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
                    ref.invalidate(productListProvider);
                  },
                  icon: const Icon(Icons.category_outlined),
                  label: Text(l10n.categories),
                ),
              ),
            Expanded(
              child: filtered.isEmpty
                  ? EmptyState(
                      icon: Icons.inventory_2_outlined,
                      message: l10n.emptyNoProducts,
                      actionLabel: widget.canEdit ? l10n.emptyAddFirstProduct : null,
                      onAction: widget.canEdit
                          ? () => _openForm(context, null)
                          : null,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
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
                    ),
            ),
          ],
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
    if (saved == true) ref.invalidate(productListProvider);
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
      ref.invalidate(productListProvider);
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
