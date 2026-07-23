import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/notification_item.dart';
import '../remote/supabase_notifications_repository.dart';
import '../remote/supabase_provider.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  return SupabaseNotificationsRepository(ref.watch(supabaseClientProvider));
});

abstract class NotificationsRepository {
  Future<List<NotificationItem>> list();
  Stream<List<NotificationItem>> watch();
  Future<int> unreadCount();
  Future<void> markRead(String id);
  Future<void> markAllRead();
}
