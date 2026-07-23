import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/category.dart';
import '../remote/supabase_provider.dart';

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  return CategoriesRepository(ref.watch(supabaseClientProvider));
});

class CategoriesRepository {
  CategoriesRepository(this._client);

  final SupabaseClient? _client;

  Future<List<Category>> list() async {
    final client = requireSupabaseClient(_client);
    final rows = await client
        .from('categories')
        .select()
        .order('name', ascending: true);
    return (rows as List)
        .map((r) => Category.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<Category> create({required String name, String? nameNp}) async {
    final client = requireSupabaseClient(_client);
    final row = await client
        .from('categories')
        .insert({'name': name, 'name_np': ?nameNp})
        .select()
        .single();
    return Category.fromJson(row);
  }

  Future<Category> update({
    required String id,
    required String name,
    String? nameNp,
  }) async {
    final client = requireSupabaseClient(_client);
    final row = await client
        .from('categories')
        .update({'name': name, 'name_np': ?nameNp})
        .eq('id', id)
        .select()
        .single();
    return Category.fromJson(row);
  }

  Future<void> delete(String id) async {
    final client = requireSupabaseClient(_client);
    await client.from('categories').delete().eq('id', id);
  }
}
