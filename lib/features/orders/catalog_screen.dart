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
import '../../web/ui/web_sheet_bridge.dart';
import 'cart_sheet.dart';
import 'providers.dart';

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
  final _cart = <String, int>{};

  int get _cartCount => _cart.values.fold(0, (a, b) => a + b);

  void _addToCart(CatalogProduct product) {
    setState(() => _cart[product.id] = (_cart[product.id] ?? 0) + 1);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final catalogAsync = ref.watch(catalogListProvider);

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

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(catalogListProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final product = filtered[index];
                    final inCart = _cart[product.id] ?? 0;
                    return Card(
                      child: ListTile(
                        leading: ProductImage(
                          storagePath: product.imageUrl,
                          size: 48,
                        ),
                        title: Text(product.name),
                        subtitle: Text(
                          '${product.unit}${product.sku != null ? ' · ${product.sku}' : ''}',
                        ),
                        trailing: inCart > 0
                            ? QtyStepper(
                                value: inCart,
                                onChanged: (v) => setState(() {
                                  if (v <= 0) {
                                    _cart.remove(product.id);
                                  } else {
                                    _cart[product.id] = v;
                                  }
                                }),
                              )
                            : IconButton(
                                icon: const Icon(
                                  Icons.add_shopping_cart_outlined,
                                ),
                                onPressed: () => _addToCart(product),
                                tooltip: l10n.addToCart,
                              ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        if (_cartCount > 0)
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: () async {
                final catalog = await ref.read(catalogListProvider.future);
                if (!context.mounted) return;
                final placed = await showAdaptiveSheet<bool>(
                  context: context,
                  title: l10n.placeOrder,
                  child: CartSheet(
                    products: catalog
                        .where((p) => _cart.containsKey(p.id))
                        .toList(),
                    quantities: Map.from(_cart),
                  ),
                );
                if (placed == true) {
                  setState(() => _cart.clear());
                  ref.invalidate(catalogListProvider);
                  ref.invalidate(ownOrderListProvider);
                }
              },
              icon: const Icon(Icons.shopping_cart),
              label: Text('${l10n.cart} ($_cartCount)'),
            ),
          ),
      ],
    );
  }
}
