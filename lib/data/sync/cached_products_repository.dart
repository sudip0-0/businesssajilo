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
    final query = _db.select(_db.localProducts)
      ..orderBy([(p) => OrderingTerm.asc(p.name)]);
    if (activeOnly) {
      query.where((p) => p.isActive.equals(true));
    }
    if (limit != null) {
      query.limit(limit, offset: offset);
    }
    final rows = await query.get();
    return rows.map(mapLocalProduct).toList();
  }

  @override
  Future<int> lowStockCount() async {
    // Compare stock_cached <= low_stock_threshold in SQL (not possible via
    // PostgREST filters; Drift customSelect can do it locally).
    final rows = await _db
        .customSelect(
          'SELECT COUNT(*) AS c FROM local_products '
          'WHERE is_active = 1 AND low_stock_threshold > 0 '
          'AND stock_cached <= low_stock_threshold',
          readsFrom: {_db.localProducts},
        )
        .get();
    return rows.first.read<int>('c');
  }

  @override
  Future<List<Product>> listLowStock({int limit = 2}) async {
    final rows = await _db
        .customSelect(
          'SELECT * FROM local_products '
          'WHERE is_active = 1 AND low_stock_threshold > 0 '
          'AND stock_cached <= low_stock_threshold '
          'ORDER BY name ASC '
          'LIMIT ?',
          variables: [Variable.withInt(limit)],
          readsFrom: {_db.localProducts},
        )
        .map((row) => _db.localProducts.map(row.data))
        .get();
    return rows.map(mapLocalProduct).toList();
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
