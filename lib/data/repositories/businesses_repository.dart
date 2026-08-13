import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/business.dart';
import '../remote/supabase_provider.dart';

final businessesRepositoryProvider = Provider<BusinessesRepository>((ref) {
  return BusinessesRepository(ref.watch(supabaseClientProvider));
});

class BusinessesRepository {
  BusinessesRepository(this._client);

  final SupabaseClient? _client;

  Future<Business?> getById(String id) async {
    if (_client == null) return null;
    final row = await _client
        .from('businesses')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return Business.fromJson(Map<String, dynamic>.from(row as Map));
  }

  Future<Business> update({
    required String id,
    required String name,
    String? nameNp,
    String? address,
    String? phone,
  }) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase is not configured');
    }
    final row = await client
        .from('businesses')
        .update({
          'name': name.trim(),
          'name_np': nameNp,
          'address': address,
          'phone': phone,
        })
        .eq('id', id)
        .select()
        .single();
    return Business.fromJson(Map<String, dynamic>.from(row as Map));
  }
}
