import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/notifications_repository.dart';
import '../../domain/models/notification_item.dart';

final notificationListProvider =
    StreamProvider.autoDispose<List<NotificationItem>>((ref) {
  return ref.watch(notificationsRepositoryProvider).watch();
});

final unreadNotificationCountProvider = Provider.autoDispose<int>((ref) {
  final notifications = ref.watch(notificationListProvider).value ?? [];
  return notifications.where((n) => n.isUnread).length;
});
