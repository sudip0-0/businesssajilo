import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/pagination.dart';
import '../../data/repositories/categories_repository.dart';
import '../../data/repositories/products_repository.dart';
import '../../domain/models/category.dart';
import '../../domain/models/product.dart';

final categoryListProvider = FutureProvider.autoDispose<List<Category>>((ref) {
  return ref.watch(categoriesRepositoryProvider).list();
});

/// Capped product list for pickers (bill form, stock-in). Pass [query] for
/// server/local search; empty query returns the first page alphabetically.
final productListProvider = FutureProvider.autoDispose
    .family<List<Product>, String>((ref, query) {
      return ref
          .watch(productsRepositoryProvider)
          .list(
            limit: kPickerPageSize,
            query: query.trim().isEmpty ? null : query,
          );
    });

final lowStockCountProvider = FutureProvider.autoDispose<int>((ref) {
  return ref.watch(productsRepositoryProvider).lowStockCount();
});

final lowStockAlertsProvider = FutureProvider.autoDispose<List<Product>>((ref) {
  return ref.watch(productsRepositoryProvider).listLowStock(limit: 2);
});

final productDetailProvider = FutureProvider.autoDispose
    .family<Product, String>((ref, id) {
      return ref.watch(productsRepositoryProvider).get(id);
    });
