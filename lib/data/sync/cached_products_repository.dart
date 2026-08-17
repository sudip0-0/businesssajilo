import 'package:drift/drift.dart';

import '../../domain/enums.dart';
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
    String? query,
    ProductStockFilter stockFilter = ProductStockFilter.all,
  }) async {
    final q = query?.trim();
    final stockSql = switch (stockFilter) {
      ProductStockFilter.all => '',
      ProductStockFilter.low =>
        'AND low_stock_threshold > 0 AND stock_cached <= low_stock_threshold ',
      ProductStockFilter.out => 'AND stock_cached <= 0 ',
      ProductStockFilter.inStock =>
        'AND stock_cached > 0 AND (low_stock_threshold <= 0 OR stock_cached > low_stock_threshold) ',
    };
    if (q != null && q.isNotEmpty) {
      final pattern = '%${q.toLowerCase()}%';
      final rows = await _db
          .customSelect(
            'SELECT * FROM local_products '
            'WHERE is_active = ? '
            'AND (lower(name) LIKE ? OR lower(ifnull(sku, \'\')) LIKE ? '
            'OR lower(ifnull(name_np, \'\')) LIKE ?) '
            '$stockSql'
            'ORDER BY name ASC '
            'LIMIT ? OFFSET ?',
            variables: [
              Variable.withBool(activeOnly),
              Variable.withString(pattern),
              Variable.withString(pattern),
              Variable.withString(pattern),
              Variable.withInt(limit ?? 50),
              Variable.withInt(offset),
            ],
            readsFrom: {_db.localProducts},
          )
          .map((row) => _db.localProducts.map(row.data))
          .get();
      return rows.map(mapLocalProduct).toList();
    }
    if (stockFilter != ProductStockFilter.all) {
      final rows = await _db
          .customSelect(
            'SELECT * FROM local_products '
            'WHERE is_active = ? $stockSql'
            'ORDER BY name ASC '
            'LIMIT ? OFFSET ?',
            variables: [
              Variable.withBool(activeOnly),
              Variable.withInt(limit ?? 50),
              Variable.withInt(offset),
            ],
            readsFrom: {_db.localProducts},
          )
          .map((row) => _db.localProducts.map(row.data))
          .get();
      return rows.map(mapLocalProduct).toList();
    }
    final select = _db.select(_db.localProducts)
      ..orderBy([(p) => OrderingTerm.asc(p.name)])
      ..where((p) => p.isActive.equals(activeOnly));
    if (limit != null) {
      select.limit(limit, offset: offset);
    }
    final rows = await select.get();
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
    required String unit,
    int costPrice = 0,
    int referencePrice = 0,
    int lowStockThreshold = 0,
  }) {
    return _remote.create(
      name: name,
      nameNp: nameNp,
      sku: sku,
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
      unit: unit,
      costPrice: costPrice,
      referencePrice: referencePrice,
      lowStockThreshold: lowStockThreshold,
      imageUrl: imageUrl,
    );
  }

  @override
  Future<void> deactivate(String id) async {
    await _remote.deactivate(id);
    await _setLocalActive(id, false);
  }

  @override
  Future<void> activate(String id) async {
    await _remote.activate(id);
    await _setLocalActive(id, true);
  }

  Future<void> _setLocalActive(String id, bool isActive) {
    return (_db.update(_db.localProducts)..where((p) => p.id.equals(id))).write(
      LocalProductsCompanion(isActive: Value(isActive)),
    );
  }

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
