import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/notification_item.dart';
import '../remote/supabase_provider.dart';

final notificationsRepositoryProvider =
    Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref.watch(supabaseClientProvider));
});

class NotificationsRepository {
  NotificationsRepository(this._client);

  final SupabaseClient? _client;

  Future<List<NotificationItem>> list() async {
    final client = _requireClient();
    final rows = await client
        .from('notifications')
        .select()
        .order('created_at', ascending: false);
    return (rows as List)
        .map((row) => NotificationItem.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Stream<List<NotificationItem>> watch() {
    final client = _requireClient();
    return client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map(
          (rows) => rows
              .map((row) => NotificationItem.fromJson(row))
              .toList(),
        );
  }

  Future<int> unreadCount() async {
    final items = await list();
    return items.where((n) => n.isUnread).length;
  }

  Future<void> markRead(String id) async {
    final client = _requireClient();
    await client
        .from('notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id)
        .isFilter('read_at', null);
  }

  Future<void> markAllRead() async {
    final client = _requireClient();
    await client
        .from('notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .isFilter('read_at', null);
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) throw Exception('Supabase not configured');
    return client;
  }
}
