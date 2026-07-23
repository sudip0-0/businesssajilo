import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/catalog_product.dart';
import '../remote/supabase_catalog_repository.dart';
import '../remote/supabase_provider.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return SupabaseCatalogRepository(ref.watch(supabaseClientProvider));
});

abstract class CatalogRepository {
  Future<List<CatalogProduct>> list();
}
