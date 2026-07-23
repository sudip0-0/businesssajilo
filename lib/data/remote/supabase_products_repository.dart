import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/product.dart';
import '../repositories/products_repository.dart';
import 'supabase_provider.dart';

class SupabaseProductsRepository implements ProductsRepository {
  SupabaseProductsRepository(this._client);

  final SupabaseClient? _client;
  static const _bucket = 'product-images';
  final Map<String, Future<String>> _signedUrlCache = {};

  @override
  Future<List<Product>> list({
    bool activeOnly = true,
    int offset = 0,
    int? limit,
    String? query,
  }) async {
    final client = requireSupabaseClient(_client);
    var built = client.from('products').select('*, categories(name)');
    if (activeOnly) {
      built = built.eq('is_active', true);
    }
    final q = query?.trim();
    if (q != null && q.isNotEmpty) {
      final pattern = '%${q.replaceAll(',', '')}%';
      built = built.or(
        'name.ilike.$pattern,sku.ilike.$pattern,name_np.ilike.$pattern',
      );
    }
    var ordered = built.order('name', ascending: true);
    if (limit != null) {
      ordered = ordered.range(offset, offset + limit - 1);
    }
    final rows = await ordered;
    return (rows as List).map(_mapProduct).toList();
  }

  @override
  Future<int> lowStockCount() async {
    final client = requireSupabaseClient(_client);
    final result = await client.rpc<dynamic>('low_stock_count');
    return (result as num?)?.toInt() ?? 0;
  }

  @override
  Future<List<Product>> listLowStock({int limit = 2}) async {
    final client = requireSupabaseClient(_client);
    final result = await client.rpc<dynamic>(
      'list_low_stock',
      params: {'p_limit': limit},
    );
    final rows = result is List ? result : const [];
    return rows
        .map((row) => Product.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  @override
  Future<Product> get(String id) async {
    final client = requireSupabaseClient(_client);
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
    final client = requireSupabaseClient(_client);
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
    final client = requireSupabaseClient(_client);
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
    final client = requireSupabaseClient(_client);
    await client.from('products').update({'is_active': false}).eq('id', id);
  }

  @override
  Future<void> activate(String id) async {
    final client = requireSupabaseClient(_client);
    await client.from('products').update({'is_active': true}).eq('id', id);
  }

  @override
  Future<String> uploadImage({
    required String businessId,
    required String productId,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final client = requireSupabaseClient(_client);
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
    final client = requireSupabaseClient(_client);
    final cached = _signedUrlCache[storagePath];
    if (cached != null) return cached;
    final future = client.storage
        .from(_bucket)
        .createSignedUrl(storagePath, 60 * 60 * 24);
    _signedUrlCache[storagePath] = future;
    // Don't cache failures.
    future.catchError((Object _) {
      _signedUrlCache.remove(storagePath);
      return '';
    });
    return future;
  }

  Product _mapProduct(dynamic row) {
    final map = Map<String, dynamic>.from(row as Map);
    final category = map.remove('categories');
    if (category is Map) {
      map['category_name'] = category['name'];
    }
    return Product.fromJson(map);
  }
}
