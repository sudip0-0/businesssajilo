import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_prefs.dart';
import '../../data/repositories/notifications_repository.dart';
import '../../domain/models/notification_item.dart';

final notificationMutePrefsProvider =
    FutureProvider.autoDispose<NotificationMutePrefs>((ref) {
      return NotificationMutePrefs.load();
    });

/// Single realtime subscription for the notifications inbox.
///
/// Unread badge count is derived from this list so we never open a second
/// Supabase `.stream()` on the same table (dual channels flap and the
/// dropdown flickers between skeleton and data).
final notificationListProvider =
    StreamProvider.autoDispose<List<NotificationItem>>((ref) {
      final prefs =
          ref.watch(notificationMutePrefsProvider).value ??
          const NotificationMutePrefs();
      return ref
          .watch(notificationsRepositoryProvider)
          .watch()
          .map((items) => excludeMutedNotifications(items, prefs));
    });

/// Unread count from the shared inbox list (capped by the list page size).
final unreadNotificationCountProvider = Provider.autoDispose<int>((ref) {
  final items = ref.watch(notificationListProvider).value;
  if (items == null) return 0;
  return items.where((item) => item.isUnread).length;
});

extension NotificationActions on WidgetRef {
  /// Marks every notification read and refreshes the shared inbox stream.
  Future<void> markAllNotificationsRead() async {
    await read(notificationsRepositoryProvider).markAllRead();
    invalidate(notificationListProvider);
  }
}

/// Hides types the current member has muted so the inbox matches send rules.
List<NotificationItem> excludeMutedNotifications(
  List<NotificationItem> items,
  NotificationMutePrefs prefs,
) {
  return items.where((item) => !prefs.mutes(item.type)).toList();
}

/// Formats unread badge label (caps at 99+).
String formatUnreadBadge(int count) {
  if (count <= 0) return '';
  if (count > 99) return '99+';
  return '$count';
}
