import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_failure.dart';
import '../../core/validation/image_upload.dart';
import '../../domain/enums.dart';
import '../../domain/models/product.dart';
import '../repositories/products_repository.dart';
import 'postgrest_filter.dart';
import 'supabase_provider.dart';

class _CachedSignedUrl {
  const _CachedSignedUrl(this.future, this.expiresAt);
  final Future<String> future;
  final DateTime expiresAt;
}

class SupabaseProductsRepository implements ProductsRepository {
  SupabaseProductsRepository(this._client);

  final SupabaseClient? _client;
  static const _bucket = 'product-images';
  static const _signedUrlTtlSeconds = 60 * 60 * 24;
  static const _cacheTtl = Duration(hours: 20);
  static const _maxCacheEntries = 500;
  final Map<String, _CachedSignedUrl> _signedUrlCache = {};

  @override
  Future<List<Product>> list({
    bool activeOnly = true,
    int offset = 0,
    int? limit,
    String? query,
    ProductStockFilter stockFilter = ProductStockFilter.all,
  }) async {
    final client = requireSupabaseClient(_client);
    if (stockFilter != ProductStockFilter.all) {
      final result = await client.rpc<dynamic>(
        'list_products_page',
        params: {
          'p_active_only': activeOnly,
          'p_query': query,
          'p_stock_filter': stockFilter.name,
          'p_offset': offset,
          'p_limit': limit ?? 50,
        },
      );
      final rows = result is List ? result : const [];
      return rows
          .map((row) => Product.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList();
    }
    var built = client.from('products').select().eq('is_active', activeOnly);
    final q = query == null ? '' : sanitizePostgrestOrIlikeQuery(query);
    if (q.isNotEmpty) {
      final pattern = '%$q%';
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
    final row = await client.from('products').select().eq('id', id).single();
    return _mapProduct(row);
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
  }) async {
    final client = requireSupabaseClient(_client);
    final row = await client
        .from('products')
        .insert({
          'name': name,
          'name_np': ?nameNp,
          'sku': ?sku,
          'unit': unit,
          'cost_price': costPrice,
          'reference_price': referencePrice,
          'low_stock_threshold': lowStockThreshold,
        })
        .select()
        .single();
    return _mapProduct(row);
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
  }) async {
    final client = requireSupabaseClient(_client);
    final row = await client
        .from('products')
        .update({
          'name': name,
          'name_np': ?nameNp,
          'sku': ?sku,
          'unit': unit,
          'cost_price': costPrice,
          'reference_price': referencePrice,
          'low_stock_threshold': lowStockThreshold,
          'image_url': ?imageUrl,
        })
        .eq('id', id)
        .select()
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
    final compressed =
        !kIsWeb && bytes.lengthInBytes > ImageUpload.compressBelowBytes
        ? await compute(ImageUpload.compressForUpload, bytes)
        : ImageUpload.compressForUpload(bytes);
    final uploadError = ImageUpload.validate(compressed);
    if (uploadError != null) {
      throw AppFailure.validation(
        detail: uploadError == ImageUploadError.tooLarge
            ? 'image too large'
            : 'invalid image type',
      );
    }
    final sniffed = ImageUpload.sniffMime(compressed)!;
    final client = requireSupabaseClient(_client);
    final ext = ImageUpload.extensionForMime(sniffed);
    final path = '$businessId/$productId.$ext';
    await client.storage
        .from(_bucket)
        .uploadBinary(
          path,
          compressed,
          fileOptions: FileOptions(contentType: sniffed, upsert: true),
        );
    // Invalidate cached signed URL so newly uploaded photo renders immediately.
    _signedUrlCache.remove(path);
    return path;
  }

  @override
  Future<String?> signedImageUrl(String? storagePath) async {
    if (storagePath == null || storagePath.isEmpty) return null;
    final client = requireSupabaseClient(_client);
    final now = DateTime.now();
    final cached = _signedUrlCache[storagePath];
    if (cached != null && now.isBefore(cached.expiresAt)) {
      return cached.future;
    }
    if (_signedUrlCache.length >= _maxCacheEntries) {
      _signedUrlCache.remove(_signedUrlCache.keys.first);
    }
    final future = client.storage
        .from(_bucket)
        .createSignedUrl(storagePath, _signedUrlTtlSeconds);
    _signedUrlCache[storagePath] = _CachedSignedUrl(future, now.add(_cacheTtl));
    // Don't cache failures.
    unawaited(
      future.catchError((Object _) {
        _signedUrlCache.remove(storagePath);
        return '';
      }),
    );
    return future;
  }

  Product _mapProduct(dynamic row) {
    final map = Map<String, dynamic>.from(row as Map);
    return Product.fromJson(map);
  }
}
