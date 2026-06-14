import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/business.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../remote/supabase_provider.dart';

final businessesRepositoryProvider = Provider<BusinessesRepository>((ref) {
  return BusinessesRepository(ref.watch(supabaseClientProvider));
});

final currentBusinessProvider = FutureProvider.autoDispose<Business?>((ref) async {
  final businessId = ref.watch(authProvider).value?.member?.businessId;
  if (businessId == null) return null;
  return ref.watch(businessesRepositoryProvider).getById(businessId);
});

class BusinessesRepository {
  BusinessesRepository(this._client);

  final SupabaseClient? _client;

  Future<Business?> getById(String id) async {
    if (_client == null) return null;
    final row = await _client.from('businesses').select().eq('id', id).maybeSingle();
    if (row == null) return null;
    return Business.fromJson(Map<String, dynamic>.from(row as Map));
  }
}
