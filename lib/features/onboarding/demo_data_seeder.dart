import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/categories_repository.dart';
import '../../data/repositories/customers_repository.dart';
import '../../data/repositories/products_repository.dart';
import '../customers/providers.dart';
import '../inventory/providers.dart';

enum DemoSeedResult { loaded, skipped }

/// Inserts sample category, products, and customer for new businesses.
class DemoDataSeeder {
  DemoDataSeeder(this._ref);

  final WidgetRef _ref;

  Future<DemoSeedResult> seed() async {
    final products = await _ref.read(productsRepositoryProvider).list();
    if (products.isNotEmpty) return DemoSeedResult.skipped;

    final categories = _ref.read(categoriesRepositoryProvider);
    final category = await categories.create(
      name: 'Beverages',
      nameNp: 'पेय पदार्थ',
    );

    final productsRepo = _ref.read(productsRepositoryProvider);
    await productsRepo.create(
      name: 'Cola 1L',
      nameNp: 'कोला १ लिटर',
      categoryId: category.id,
      unit: 'piece',
      costPrice: 4500,
      referencePrice: 6000,
      lowStockThreshold: 5,
    );
    await productsRepo.create(
      name: 'Mineral Water',
      nameNp: 'मिनरल वाटर',
      categoryId: category.id,
      unit: 'piece',
      costPrice: 1500,
      referencePrice: 2500,
      lowStockThreshold: 10,
    );
    await productsRepo.create(
      name: 'Juice Pack',
      nameNp: 'जुस प्याक',
      categoryId: category.id,
      unit: 'piece',
      costPrice: 3500,
      referencePrice: 5000,
      lowStockThreshold: 5,
    );

    final customersRepo = _ref.read(customersRepositoryProvider);
    await customersRepo.createWithCredentials(
      email:
          'demo-customer-${DateTime.now().millisecondsSinceEpoch}@demo.local',
      password: 'DemoPass123!',
      displayName: 'Ram Store',
      shopName: 'Ram Store',
      contactName: 'Ram Bahadur',
      phone: '9800000000',
      openingBalance: 0,
    );

    _ref.invalidate(productListProvider);
    _ref.invalidate(customerListProvider);
    _ref.invalidate(lowStockCountProvider);

    return DemoSeedResult.loaded;
  }
}
