import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/notifications_repository.dart';
import '../../domain/models/notification_item.dart';

final notificationListProvider =
    StreamProvider.autoDispose<List<NotificationItem>>((ref) {
      return ref.watch(notificationsRepositoryProvider).watch();
    });

/// Exact unread count — refreshes when the notification stream emits.
final unreadNotificationCountProvider = StreamProvider.autoDispose<int>((ref) async* {
  final repo = ref.watch(notificationsRepositoryProvider);
  await for (final _ in repo.watch()) {
    yield await repo.unreadCount();
  }
});

/// Formats unread badge label (caps at 99+).
String formatUnreadBadge(int count) {
  if (count <= 0) return '';
  if (count > 99) return '99+';
  return '$count';
}
