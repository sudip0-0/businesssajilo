import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/catalog_product.dart';
import '../repositories/catalog_repository.dart';
import 'supabase_provider.dart';

class SupabaseCatalogRepository implements CatalogRepository {
  SupabaseCatalogRepository(this._client);

  final SupabaseClient? _client;

  @override
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
