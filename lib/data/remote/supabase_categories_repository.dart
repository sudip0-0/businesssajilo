import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/category.dart';
import '../repositories/categories_repository.dart';
import 'supabase_provider.dart';

class SupabaseCategoriesRepository implements CategoriesRepository {
  SupabaseCategoriesRepository(this._client);

  final SupabaseClient? _client;

  @override
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

  @override
  Future<Category> create({required String name, String? nameNp}) async {
    final client = requireSupabaseClient(_client);
    final row = await client
        .from('categories')
        .insert({'name': name, 'name_np': ?nameNp})
        .select()
        .single();
    return Category.fromJson(row);
  }

  @override
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

  @override
  Future<void> delete(String id) async {
    final client = requireSupabaseClient(_client);
    await client.from('categories').delete().eq('id', id);
  }
}
