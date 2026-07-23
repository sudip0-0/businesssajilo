import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/category.dart';
import '../remote/supabase_categories_repository.dart';
import '../remote/supabase_provider.dart';

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  return SupabaseCategoriesRepository(ref.watch(supabaseClientProvider));
});

abstract class CategoriesRepository {
  Future<List<Category>> list();
  Future<Category> create({required String name, String? nameNp});
  Future<Category> update({
    required String id,
    required String name,
    String? nameNp,
  });
  Future<void> delete(String id);
}
