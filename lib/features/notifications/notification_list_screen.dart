import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/utils/bs_date.dart';
import '../../core/ui/async_body.dart';
import '../../core/ui/empty_state.dart';
import '../../data/repositories/notifications_repository.dart';
import '../../domain/models/notification_item.dart';
import '../auth/providers/auth_provider.dart';
import 'notification_labels.dart';
import 'notification_navigation.dart';
import 'providers.dart';

class NotificationListScreen extends ConsumerWidget {
  const NotificationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notificationsAsync = ref.watch(notificationListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifications),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(notificationsRepositoryProvider).markAllRead();
            },
            child: Text(l10n.markAllRead),
          ),
        ],
      ),
      body: AsyncBody(
        value: notificationsAsync,
        onRetry: () => ref.invalidate(notificationListProvider),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.notifications_none_outlined,
              message: l10n.noNotifications,
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(notificationListProvider),
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = items[index];
                return _NotificationTile(item: item);
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.item});

  final NotificationItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final dateStr = item.createdAt != null
        ? BsDate.both(item.createdAt!)
        : '—';

    return ListTile(
      leading: Icon(notificationIcon(item.type)),
      title: Text(notificationTitle(l10n, item)),
      subtitle: Text(dateStr),
      trailing: item.isUnread
          ? const Icon(Icons.circle, size: 10, color: Colors.blue)
          : null,
      onTap: () async {
        if (item.isUnread) {
          await ref.read(notificationsRepositoryProvider).markRead(item.id);
        }
        if (context.mounted) {
          final role = ref.read(authProvider).value?.member?.role;
          openNotificationTarget(context, item, role: role);
        }
      },
    );
  }
}
