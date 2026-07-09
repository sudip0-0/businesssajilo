import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/product.dart';
import '../repositories/products_repository.dart';

class SupabaseProductsRepository implements ProductsRepository {
  SupabaseProductsRepository(this._client);

  final SupabaseClient? _client;
  static const _bucket = 'product-images';

  @override
  Future<List<Product>> list({
    bool activeOnly = true,
    int offset = 0,
    int? limit,
  }) async {
    final client = _requireClient();
    var query = client.from('products').select('*, categories(name)');
    if (activeOnly) {
      query = query.eq('is_active', true);
    }
    var ordered = query.order('name', ascending: true);
    if (limit != null) {
      ordered = ordered.range(offset, offset + limit - 1);
    }
    final rows = await ordered;
    return (rows as List).map(_mapProduct).toList();
  }

  @override
  Future<int> lowStockCount() async {
    // PostgREST cannot compare two columns in a filter, so fetch only the
    // two columns needed instead of full product rows.
    final client = _requireClient();
    final rows = await client
        .from('products')
        .select('stock_cached, low_stock_threshold')
        .eq('is_active', true)
        .gt('low_stock_threshold', 0);
    var count = 0;
    for (final row in rows as List) {
      final map = row as Map;
      final stock = (map['stock_cached'] as num?)?.toInt() ?? 0;
      final threshold = (map['low_stock_threshold'] as num?)?.toInt() ?? 0;
      if (stock <= threshold) count++;
    }
    return count;
  }

  @override
  Future<List<Product>> listLowStock({int limit = 2}) async {
    // PostgREST cannot compare two columns; fetch candidates then filter.
    final client = _requireClient();
    final rows = await client
        .from('products')
        .select('*, categories(name)')
        .eq('is_active', true)
        .gt('low_stock_threshold', 0)
        .order('name', ascending: true);
    final low = <Product>[];
    for (final row in rows as List) {
      final product = _mapProduct(row);
      if (product.stockCached <= product.lowStockThreshold) {
        low.add(product);
        if (low.length >= limit) break;
      }
    }
    return low;
  }

  @override
  Future<Product> get(String id) async {
    final client = _requireClient();
    final row = await client
        .from('products')
        .select('*, categories(name)')
        .eq('id', id)
        .single();
    return _mapProduct(row);
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
  }) async {
    final client = _requireClient();
    final row = await client
        .from('products')
        .insert({
          'name': name,
          'name_np': ?nameNp,
          'sku': ?sku,
          'category_id': ?categoryId,
          'unit': unit,
          'cost_price': costPrice,
          'reference_price': referencePrice,
          'low_stock_threshold': lowStockThreshold,
        })
        .select('*, categories(name)')
        .single();
    return _mapProduct(row);
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
  }) async {
    final client = _requireClient();
    final row = await client
        .from('products')
        .update({
          'name': name,
          'name_np': ?nameNp,
          'sku': ?sku,
          'category_id': ?categoryId,
          'unit': unit,
          'cost_price': costPrice,
          'reference_price': referencePrice,
          'low_stock_threshold': lowStockThreshold,
          'image_url': ?imageUrl,
        })
        .eq('id', id)
        .select('*, categories(name)')
        .single();
    return _mapProduct(row);
  }

  @override
  Future<void> deactivate(String id) async {
    final client = _requireClient();
    await client.from('products').update({'is_active': false}).eq('id', id);
  }

  @override
  Future<String> uploadImage({
    required String businessId,
    required String productId,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final client = _requireClient();
    final ext = mimeType.contains('png')
        ? 'png'
        : mimeType.contains('webp')
        ? 'webp'
        : 'jpg';
    final path = '$businessId/$productId.$ext';
    await client.storage
        .from(_bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: mimeType, upsert: true),
        );
    return path;
  }

  @override
  Future<String?> signedImageUrl(String? storagePath) async {
    if (storagePath == null || storagePath.isEmpty) return null;
    final client = _requireClient();
    return client.storage
        .from(_bucket)
        .createSignedUrl(storagePath, 60 * 60 * 24);
  }

  Product _mapProduct(dynamic row) {
    final map = Map<String, dynamic>.from(row as Map);
    final category = map.remove('categories');
    if (category is Map) {
      map['category_name'] = category['name'];
    }
    return Product.fromJson(map);
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) throw Exception('Supabase not configured');
    return client;
  }
}
