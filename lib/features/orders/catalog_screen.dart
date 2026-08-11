import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/list_skeleton.dart';
import '../../core/ui/qty_stepper.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../domain/models/catalog_product.dart';
import '../inventory/product_image.dart';
import 'cart_provider.dart';

final catalogListProvider = FutureProvider.autoDispose<List<CatalogProduct>>((
  ref,
) {
  return ref.watch(catalogRepositoryProvider).list();
});

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  String _query = '';

  int _columnCount(double width) {
    if (width >= 1100) return 4;
    if (width >= 820) return 3;
    if (width >= 560) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final catalogAsync = ref.watch(catalogListProvider);
    final cart = ref.watch(cartProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            decoration: InputDecoration(
              hintText: l10n.filterProducts,
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          ),
        ),
        Expanded(
          child: catalogAsync.when(
            loading: () => const ListSkeleton(),
            error: (e, _) => ErrorState(
              message: l10n.loadingFailed,
              onRetry: () => ref.invalidate(catalogListProvider),
            ),
            data: (products) {
              final filtered = products.where((p) {
                if (_query.isEmpty) return true;
                return p.name.toLowerCase().contains(_query) ||
                    (p.sku?.toLowerCase().contains(_query) ?? false) ||
                    (p.nameNp?.contains(_query) ?? false);
              }).toList();

              if (filtered.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(catalogListProvider),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      EmptyState(
                        icon: Icons.storefront_outlined,
                        message: l10n.emptyCatalog,
                      ),
                    ],
                  ),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final columns = _columnCount(constraints.maxWidth);
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(catalogListProvider),
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      physics: const AlwaysScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: columns >= 3 ? 0.78 : 0.9,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final product = filtered[index];
                        final inCart = cart[product.id] ?? 0;
                        return _CatalogProductCard(
                          product: product,
                          qty: inCart,
                          addLabel: l10n.addToCart,
                          onAdd: () => ref
                              .read(cartProvider.notifier)
                              .addOne(product.id),
                          onQtyChanged: (v) => ref
                              .read(cartProvider.notifier)
                              .setQty(product.id, v),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CatalogProductCard extends StatelessWidget {
  const _CatalogProductCard({
    required this.product,
    required this.qty,
    required this.addLabel,
    required this.onAdd,
    required this.onQtyChanged,
  });

  final CatalogProduct product;
  final int qty;
  final String addLabel;
  final VoidCallback onAdd;
  final ValueChanged<int> onQtyChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: ProductImage(storagePath: product.imageUrl, size: 72),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 2),
            Text(
              '${product.unit}${product.sku != null ? ' · ${product.sku}' : ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: qty > 0
                  ? QtyStepper(value: qty, onChanged: onQtyChanged)
                  : IconButton.filledTonal(
                      onPressed: onAdd,
                      icon: const Icon(Icons.add_shopping_cart_outlined),
                      tooltip: addLabel,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
