import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/product.dart';
import '../remote/supabase_products_repository.dart';
import '../remote/supabase_provider.dart';
import '../sync/cached_products_repository.dart';
import '../sync/sync_providers.dart';

final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  final remote = SupabaseProductsRepository(ref.watch(supabaseClientProvider));
  final bundle = ref.watch(syncBundleProvider);
  if (bundle != null) {
    return CachedProductsRepository(db: bundle.db, remote: remote);
  }
  return remote;
});

abstract class ProductsRepository {
  Future<List<Product>> list({
    bool activeOnly = true,
    int offset = 0,
    int? limit,
    String? query,
  });
  Future<int> lowStockCount();

  /// Active products at or below their low-stock threshold, capped for dashboards.
  Future<List<Product>> listLowStock({int limit = 2});
  Future<Product> get(String id);
  Future<Product> create({
    required String name,
    String? nameNp,
    String? sku,
    String? categoryId,
    required String unit,
    int costPrice,
    int referencePrice,
    int lowStockThreshold,
  });
  Future<Product> update({
    required String id,
    required String name,
    String? nameNp,
    String? sku,
    String? categoryId,
    required String unit,
    int costPrice,
    int referencePrice,
    int lowStockThreshold,
    String? imageUrl,
  });
  Future<void> deactivate(String id);
  Future<String> uploadImage({
    required String businessId,
    required String productId,
    required Uint8List bytes,
    required String mimeType,
  });
  Future<String?> signedImageUrl(String? storagePath);
}

const _uuid = Uuid();
String newProductId() => _uuid.v4();
