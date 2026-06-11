import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/products_repository.dart';
import '../../domain/models/product.dart';

final productListProvider = FutureProvider.autoDispose<List<Product>>((ref) {
  return ref.watch(productsRepositoryProvider).list();
});

final lowStockCountProvider = FutureProvider.autoDispose<int>((ref) {
  return ref.watch(productsRepositoryProvider).lowStockCount();
});

final productDetailProvider =
    FutureProvider.autoDispose.family<Product, String>((ref, id) {
  return ref.watch(productsRepositoryProvider).get(id);
});
