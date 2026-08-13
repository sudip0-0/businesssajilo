import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_prefs.dart';
import '../remote/supabase_provider.dart';

final memberSettingsRepositoryProvider = Provider<MemberSettingsRepository>((
  ref,
) {
  return MemberSettingsRepository(ref.watch(supabaseClientProvider));
});

class MemberSettingsRepository {
  MemberSettingsRepository(this._client);

  final SupabaseClient? _client;

  Future<NotificationMutePrefs?> fetchMutedNotificationPrefs() async {
    final client = requireSupabaseClient(_client);
    final userId = client.auth.currentUser?.id;
    if (userId == null) return null;
    final row = await client
        .from('members')
        .select('notification_prefs')
        .eq('auth_user_id', userId)
        .eq('is_active', true)
        .maybeSingle();
    if (row == null) return null;
    return NotificationMutePrefs.fromNotificationPrefs(
      row['notification_prefs'],
    );
  }

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
