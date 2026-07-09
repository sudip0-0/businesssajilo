import 'package:drift/drift.dart';

import '../../domain/models/product.dart';
import '../local/app_database.dart';
import '../local/local_mappers.dart';
import '../remote/supabase_products_repository.dart';
import '../repositories/products_repository.dart';

class CachedProductsRepository implements ProductsRepository {
  CachedProductsRepository({
    required AppDatabase db,
    required SupabaseProductsRepository remote,
  }) : _db = db,
       _remote = remote;

  final AppDatabase _db;
  final SupabaseProductsRepository _remote;

  @override
  Future<List<Product>> list({
    bool activeOnly = true,
    int offset = 0,
    int? limit,
  }) async {
    var query = _db.select(_db.localProducts);
    if (activeOnly) {
      query = query..where((p) => p.isActive.equals(true));
    }
    final rows = await query.get();
    rows.sort((a, b) => a.name.compareTo(b.name));
    final mapped = rows.map(mapLocalProduct).toList();
    if (limit == null) return mapped;
    return mapped.skip(offset).take(limit).toList();
  }

  @override
  Future<int> lowStockCount() async {
    final products = await list();
    return products
        .where(
          (p) =>
              p.lowStockThreshold > 0 && p.stockCached <= p.lowStockThreshold,
        )
        .length;
  }

  @override
  Future<List<Product>> listLowStock({int limit = 2}) async {
    final rows =
        await (_db.select(_db.localProducts)
              ..where((p) => p.isActive.equals(true))
              ..where((p) => p.lowStockThreshold.isBiggerThanValue(0)))
            .get();
    final low =
        rows
            .where((p) => p.stockCached <= p.lowStockThreshold)
            .map(mapLocalProduct)
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    return low.take(limit).toList();
  }

  @override
  Future<Product> get(String id) async {
    final row = await (_db.select(
      _db.localProducts,
    )..where((p) => p.id.equals(id))).getSingle();
    return mapLocalProduct(row);
  }

  @override
  Future<Product> create({
    required String name,
    String? nameNp,
    String? sku,
    String? categoryId,
    required String unit,
    int costPrice = 0,
    int referencePrice = 0,
    int lowStockThreshold = 0,
  }) {
    return _remote.create(
      name: name,
      nameNp: nameNp,
      sku: sku,
      categoryId: categoryId,
      unit: unit,
      costPrice: costPrice,
      referencePrice: referencePrice,
      lowStockThreshold: lowStockThreshold,
    );
  }

  @override
  Future<Product> update({
    required String id,
    required String name,
    String? nameNp,
    String? sku,
    String? categoryId,
    required String unit,
    int costPrice = 0,
    int referencePrice = 0,
    int lowStockThreshold = 0,
    String? imageUrl,
  }) {
    return _remote.update(
      id: id,
      name: name,
      nameNp: nameNp,
      sku: sku,
      categoryId: categoryId,
      unit: unit,
      costPrice: costPrice,
      referencePrice: referencePrice,
      lowStockThreshold: lowStockThreshold,
      imageUrl: imageUrl,
    );
  }

  @override
  Future<void> deactivate(String id) => _remote.deactivate(id);

  @override
  Future<String> uploadImage({
    required String businessId,
    required String productId,
    required Uint8List bytes,
    required String mimeType,
  }) {
    return _remote.uploadImage(
      businessId: businessId,
      productId: productId,
      bytes: bytes,
      mimeType: mimeType,
    );
  }

  @override
  Future<String?> signedImageUrl(String? storagePath) {
    return _remote.signedImageUrl(storagePath);
  }
}
