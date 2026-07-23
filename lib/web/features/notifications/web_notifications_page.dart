import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/async_body.dart';
import '../../../core/utils/bs_date.dart';
import '../../../data/repositories/notifications_repository.dart';
import '../../../domain/models/notification_item.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/notifications/notification_labels.dart';
import '../../../features/notifications/providers.dart';
import '../../navigation/web_notification_navigation.dart';
import '../../theme/web_palette.dart';
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
        useSkeleton: false,
        data: (items) {
          if (items.isEmpty) {
            return WebEmptyState(
              message: l10n.noNotifications,
              icon: PhosphorIconsRegular.bell,
            );
          }

          return DecoratedBox(
            decoration: BoxDecoration(
              color: WebPalette.card,
              borderRadius: BorderRadius.circular(BsRadii.lg),
              border: Border.all(color: WebPalette.hairline),
              boxShadow: WebPalette.cardShadow,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(BsRadii.lg),
              child: RefreshIndicator(
                color: WebPalette.navy,
                onRefresh: () async => ref.invalidate(notificationListProvider),
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: WebPalette.hairline),
                  itemBuilder: (context, index) {
                    return _WebNotificationRow(item: items[index]);
                  },
                ),
              ),
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
    final dateStr = item.createdAt != null ? BsDate.both(item.createdAt!) : '—';
    final theme = Theme.of(context);

    return Material(
      color: item.isUnread ? WebPalette.navyWash : WebPalette.card,
      child: InkWell(
        onTap: () async {
          if (item.isUnread) {
            await ref.read(notificationsRepositoryProvider).markRead(item.id);
          }
          if (context.mounted) {
            final role = ref.read(authProvider).value?.member?.role;
            openWebNotificationTarget(context, item, role: role);
          }
        },
        hoverColor: WebPalette.paperDeep.withValues(alpha: 0.55),
        child: ListTile(
          leading: Icon(notificationIcon(item.type), color: WebPalette.navy),
          title: Text(
            notificationTitle(l10n, item),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: WebPalette.ink,
              fontWeight: item.isUnread ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          subtitle: Text(
            dateStr,
            style: theme.textTheme.bodySmall?.copyWith(
              color: WebPalette.inkSoft,
            ),
          ),
          trailing: item.isUnread
              ? const Icon(
                  PhosphorIconsFill.circle,
                  size: 10,
                  color: WebPalette.brass,
                )
              : Icon(
                  PhosphorIconsRegular.caretRight,
                  size: 16,
                  color: WebPalette.inkFaint,
                ),
        ),
      ),
    );
  }
}
