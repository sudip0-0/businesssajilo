import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_prefs.dart';
import '../../data/repositories/notifications_repository.dart';
import '../../domain/models/notification_item.dart';

final notificationMutePrefsProvider =
    FutureProvider.autoDispose<NotificationMutePrefs>((ref) {
      return NotificationMutePrefs.load();
    });

/// Single realtime subscription for the notifications inbox (capped).
///
/// Full history uses [notificationHistoryProvider] so we never open a second
/// Supabase `.stream()` on the same table.
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

/// Authoritative unread badge count from the database, not the capped stream.
final unreadNotificationCountProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  final prefs =
      ref.watch(notificationMutePrefsProvider).value ??
      const NotificationMutePrefs();
  ref.watch(notificationListProvider);
  return ref
      .watch(notificationsRepositoryProvider)
      .unreadCount(excludedTypes: prefs.mutedTypes);
});

extension NotificationActions on WidgetRef {
  /// Marks every notification read and refreshes inbox + badge.
  Future<void> markAllNotificationsRead() async {
    await read(notificationsRepositoryProvider).markAllRead();
    invalidate(notificationListProvider);
    invalidate(unreadNotificationCountProvider);
  }
}

/// Hides types the current member has muted so the inbox matches send rules.
List<NotificationItem> excludeMutedNotifications(
  List<NotificationItem> items,
  NotificationMutePrefs prefs,
) {
  return items.where((item) => !prefs.mutes(item.type)).toList();
}

/// Merges live stream items into a paginated history without duplicates.
List<NotificationItem> mergeNotificationPages({
  required List<NotificationItem> live,
  required List<NotificationItem> history,
}) {
  final seen = <String>{};
  final merged = <NotificationItem>[];
  for (final item in [...live, ...history]) {
    if (seen.add(item.id)) merged.add(item);
  }
  merged.sort((a, b) {
    final aAt = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bAt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bAt.compareTo(aAt);
  });
  return merged;
}

/// Formats unread badge label (caps at 99+).
String formatUnreadBadge(int count) {
  if (count <= 0) return '';
  if (count > 99) return '99+';
  return '$count';
}
