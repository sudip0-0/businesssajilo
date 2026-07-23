import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/notification_item.dart';
import '../repositories/notifications_repository.dart';
import 'supabase_provider.dart';

class SupabaseNotificationsRepository implements NotificationsRepository {
  SupabaseNotificationsRepository(this._client);

  final SupabaseClient? _client;

  static const _listCap = 100;

  @override
  Future<List<NotificationItem>> list() async {
    final client = requireSupabaseClient(_client);
    final rows = await client
        .from('notifications')
        .select()
        .order('created_at', ascending: false)
        .limit(_listCap);
    return (rows as List)
        .map((row) => NotificationItem.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Stream<List<NotificationItem>> watch() {
    final client = requireSupabaseClient(_client);
    return client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map(
          (rows) => rows
              .take(_listCap)
              .map((row) => NotificationItem.fromJson(row))
              .toList(),
        );
  }

  @override
  Future<int> unreadCount() async {
    final client = requireSupabaseClient(_client);
    final rows = await client
        .from('notifications')
        .select('id')
        .isFilter('read_at', null);
    return (rows as List).length;
  }

  @override
  Future<void> markRead(String id) async {
    final client = requireSupabaseClient(_client);
    await client
        .from('notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id)
        .isFilter('read_at', null);
  }

  @override
  Future<void> markAllRead() async {
    final client = requireSupabaseClient(_client);
    await client
        .from('notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .isFilter('read_at', null);
  }
}
