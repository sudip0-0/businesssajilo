import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/product.dart';
import '../local/app_database.dart';
import '../remote/supabase_provider.dart';
import '../sync/sync_providers.dart';

class ProductImportRpcResult {
  const ProductImportRpcResult({
    required this.product,
    this.movementId,
    required this.created,
  });

  final Product product;
  final String? movementId;
  final bool created;
}

/// Atomic, idempotent product + opening-stock creation backed by
/// `create_product_with_stock` RPC (migration 62).
abstract class ProductImportRepository {
  Future<ProductImportRpcResult> createProductWithStock({
    required String opId,
    required String name,
    String? nameNp,
    String? sku,
    String unit = 'piece',
    int costPrice = 0,
    int referencePrice = 0,
    int lowStockThreshold = 0,
    int openingStock = 0,
    String openingStockReason = 'Opening stock',
  });
}

/// Null when no Supabase client is configured (e.g. unconfigured VM unit tests).
final productImportRepositoryProvider = Provider<ProductImportRepository?>((
  ref,
) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  final bundle = ref.watch(syncBundleProvider);
  return SupabaseProductImportRepository(client: client, localDb: bundle?.db);
});

class SupabaseProductImportRepository implements ProductImportRepository {
  SupabaseProductImportRepository({
    required SupabaseClient client,
    AppDatabase? localDb,
  }) : _client = client,
       _localDb = localDb;

  final SupabaseClient _client;
  final AppDatabase? _localDb;

  @override
  Future<ProductImportRpcResult> createProductWithStock({
    required String opId,
    required String name,
    String? nameNp,
    String? sku,
    String unit = 'piece',
    int costPrice = 0,
    int referencePrice = 0,
    int lowStockThreshold = 0,
    int openingStock = 0,
    String openingStockReason = 'Opening stock',
  }) async {
    final raw = await _client.rpc<dynamic>(
      'create_product_with_stock',
      params: {
        'p': {
          'op_id': opId,
          'name': name,
          if (nameNp != null && nameNp.isNotEmpty) 'name_np': nameNp,
          if (sku != null && sku.isNotEmpty) 'sku': sku,
          'unit': unit,
          'cost_price': costPrice,
          'reference_price': referencePrice,
          'low_stock_threshold': lowStockThreshold,
          'opening_stock': openingStock,
          'opening_stock_reason': openingStockReason,
        },
      },
    );
    if (raw is! Map) {
      throw StateError('Unexpected create_product_with_stock response');
    }
    final map = Map<String, dynamic>.from(raw);
    final rawProduct = map['product'];
    if (rawProduct is! Map) {
      throw StateError('Missing product in create_product_with_stock response');
    }
    final product = Product.fromJson(Map<String, dynamic>.from(rawProduct));
    await _upsertLocal(product);
    return ProductImportRpcResult(
      product: product,
      movementId: map['movement_id'] as String?,
      created: map['created'] != false,
    );
  }

  Future<void> _upsertLocal(Product p) async {
    final db = _localDb;
    if (db == null) return;
    await db
        .into(db.localProducts)
        .insertOnConflictUpdate(
          LocalProductsCompanion.insert(
            id: p.id,
            businessId: p.businessId,
            name: p.name,
            nameNp: Value(p.nameNp),
            sku: Value(p.sku),
            unit: p.unit,
            costPrice: Value(p.costPrice),
            referencePrice: Value(p.referencePrice),
            imageUrl: Value(p.imageUrl),
            lowStockThreshold: Value(p.lowStockThreshold),
            stockCached: Value(p.stockCached),
            isActive: Value(p.isActive),
            updatedAt: p.updatedAt ?? DateTime.now().toUtc(),
            createdAt: Value(p.createdAt),
          ),
        );
  }
}
