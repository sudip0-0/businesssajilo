import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/pagination.dart';
import '../../data/repositories/products_repository.dart';
import '../../domain/models/product.dart';

/// Bumped after product/stock writes so paginated inventory lists can refresh.
final inventoryRevisionProvider = NotifierProvider<InventoryRevision, int>(
  InventoryRevision.new,
);

class InventoryRevision extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

void bumpInventoryRevision(WidgetRef ref) {
  ref.read(inventoryRevisionProvider.notifier).bump();
}

/// Bridge for callers that only have [Ref] (e.g. bill-save invalidation).
void bumpInventoryRevisionFromRef(Ref ref) {
  ref.read(inventoryRevisionProvider.notifier).bump();
}

/// Capped product list for pickers (bill form, stock-in). Pass [query] for
/// server/local search; empty query returns the first page alphabetically.
final productListProvider = FutureProvider.autoDispose
    .family<List<Product>, String>((ref, query) {
      ref.watch(inventoryRevisionProvider);
      return ref
          .watch(productsRepositoryProvider)
          .list(
            limit: kPickerPageSize,
            query: query.trim().isEmpty ? null : query,
          );
    });

final lowStockCountProvider = FutureProvider.autoDispose<int>((ref) {
  ref.watch(inventoryRevisionProvider);
  return ref.watch(productsRepositoryProvider).lowStockCount();
});

final lowStockAlertsProvider = FutureProvider.autoDispose<List<Product>>((ref) {
  ref.watch(inventoryRevisionProvider);
  return ref.watch(productsRepositoryProvider).listLowStock(limit: 2);
});

/// Every active low-stock product (for the reorder screen), capped defensively.
final lowStockProductsProvider = FutureProvider.autoDispose<List<Product>>((
  ref,
) async {
  ref.watch(inventoryRevisionProvider);
  final count = await ref.watch(productsRepositoryProvider).lowStockCount();
  final limit = count.clamp(1, 200);
  return ref.watch(productsRepositoryProvider).listLowStock(limit: limit);
});

final productDetailProvider = FutureProvider.autoDispose
    .family<Product, String>((ref, id) {
      ref.watch(inventoryRevisionProvider);
      return ref.watch(productsRepositoryProvider).get(id);
    });
