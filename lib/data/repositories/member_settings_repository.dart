import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../remote/supabase_provider.dart';

final memberSettingsRepositoryProvider = Provider<MemberSettingsRepository>((
  ref,
) {
  return MemberSettingsRepository(ref.watch(supabaseClientProvider));
});

class MemberSettingsRepository {
  MemberSettingsRepository(this._client);

  final SupabaseClient? _client;

  Future<void> updateMutedNotificationTypes({
    required List<String> muted,
  }) async {
    final client = requireSupabaseClient(_client);
    await client.rpc<dynamic>(
      'update_own_notification_prefs',
      params: {'p_muted': muted},
    );
  }
}
