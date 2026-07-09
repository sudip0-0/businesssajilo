import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/categories_repository.dart';
import '../../data/repositories/products_repository.dart';
import '../../domain/models/category.dart';
import '../../domain/models/product.dart';

final categoryListProvider = FutureProvider.autoDispose<List<Category>>((ref) {
  return ref.watch(categoriesRepositoryProvider).list();
});

final productListProvider = FutureProvider.autoDispose<List<Product>>((ref) {
  return ref.watch(productsRepositoryProvider).list();
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
