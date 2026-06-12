import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/ui/async_body.dart';
import '../../../core/utils/bs_date.dart';
import '../../../data/repositories/notifications_repository.dart';
import '../../../domain/models/notification_item.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/notifications/notification_labels.dart';
import '../../../features/notifications/providers.dart';
import '../../navigation/web_notification_navigation.dart';
import '../../ui/web_data_table.dart';
import '../../ui/web_empty_state.dart';
import '../web_page_scaffold.dart';

class WebNotificationsPage extends ConsumerWidget {
  const WebNotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notificationsAsync = ref.watch(notificationListProvider);

    return WebPageScaffold(
      title: l10n.notifications,
      breadcrumbs: [l10n.notifications],
      actions: [
        TextButton(
          onPressed: () async {
            await ref.read(notificationsRepositoryProvider).markAllRead();
          },
          child: Text(l10n.markAllRead),
        ),
      ],
      body: AsyncBody(
        value: notificationsAsync,
        onRetry: () => ref.invalidate(notificationListProvider),
        data: (items) {
          if (items.isEmpty) {
            return WebEmptyState(
              message: l10n.noNotifications,
              icon: PhosphorIconsRegular.bell,
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(notificationListProvider),
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = items[index];
                return _WebNotificationRow(item: item);
              },
            ),
          );
        },
      ),
    );
  }
}

class _WebNotificationRow extends ConsumerWidget {
  const _WebNotificationRow({required this.item});

  final NotificationItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final dateStr =
        item.createdAt != null ? BsDate.both(item.createdAt!) : '—';

    return WebHoverableRow(
      onTap: () async {
        if (item.isUnread) {
          await ref.read(notificationsRepositoryProvider).markRead(item.id);
        }
        if (context.mounted) {
          final role = ref.read(authProvider).value?.member?.role;
          openWebNotificationTarget(context, item, role: role);
        }
      },
      child: ListTile(
        leading: Icon(notificationIcon(item.type)),
        title: Text(notificationTitle(l10n, item)),
        subtitle: Text(dateStr),
        trailing: item.isUnread
            ? Icon(PhosphorIconsFill.circle, size: 10, color: Colors.blue)
            : Icon(PhosphorIconsRegular.caretRight, size: 16),
      ),
    );
  }
}
