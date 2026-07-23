import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/catalog_product.dart';
import '../remote/supabase_provider.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository(ref.watch(supabaseClientProvider));
});

class CatalogRepository {
  CatalogRepository(this._client);

  final SupabaseClient? _client;

  Future<List<CatalogProduct>> list() async {
    final client = requireSupabaseClient(_client);
    final rows = await client.rpc('list_catalog_products');
    return (rows as List).map(_mapRow).toList();
  }

  CatalogProduct _mapRow(dynamic row) {
    final map = Map<String, dynamic>.from(row as Map);
    return CatalogProduct.fromJson(map);
  }
}
