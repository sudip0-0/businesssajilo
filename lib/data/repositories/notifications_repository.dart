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
  Future<List<NotificationItem>> list({int offset = 0, int limit = 30});
  Stream<List<NotificationItem>> watch({int limit = 50});
  Future<int> unreadCount({Iterable<String> excludedTypes = const []});
  Future<void> markRead(String id);
  Future<void> markAllRead();
}
