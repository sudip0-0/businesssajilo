import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../remote/supabase_provider.dart';

final deviceTokensRepositoryProvider = Provider<DeviceTokensRepository>((ref) {
  return DeviceTokensRepository(ref.watch(supabaseClientProvider));
});

class DeviceTokensRepository {
  DeviceTokensRepository(this._client);

  final SupabaseClient? _client;

  Future<void> upsert({required String memberId, required String token}) async {
    final client = _requireClient();
    await client.from('device_tokens').upsert({
      'member_id': memberId,
      'token': token,
      'platform': _platformName(),
    }, onConflict: 'member_id,token');
  }

  Future<void> deleteToken({
    required String memberId,
    required String token,
  }) async {
    final client = _requireClient();
    await client
        .from('device_tokens')
        .delete()
        .eq('member_id', memberId)
        .eq('token', token);
  }

  String _platformName() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.android:
        return 'android';
      default:
        return 'web';
    }
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) throw Exception('Supabase not configured');
    return client;
  }
}
