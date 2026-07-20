import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/async_body.dart';
import '../../core/utils/bs_date.dart';
import '../../data/repositories/notifications_repository.dart';
import '../../domain/models/notification_item.dart';
import 'notification_labels.dart';
import 'providers.dart';

const notificationDropdownWidth = 360.0;
const notificationDropdownMaxHeight = 440.0;

typedef NotificationOpenCallback =
    void Function(BuildContext context, NotificationItem item);

/// Opens a dropdown panel anchored to the widget that owns [buttonContext].
Future<void> showNotificationDropdown({
  required BuildContext buttonContext,
  required NotificationOpenCallback onOpenItem,
  VoidCallback? onViewAll,
}) async {
  final box = buttonContext.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize) return;

  final overlay = Overlay.of(buttonContext);
  final overlayBox = overlay.context.findRenderObject() as RenderBox?;
  if (overlayBox == null) return;

  final topLeft = box.localToGlobal(Offset.zero, ancestor: overlayBox);
  final size = MediaQuery.sizeOf(buttonContext);
  final panelTop = topLeft.dy + box.size.height + 4;
  final preferredRight = size.width - (topLeft.dx + box.size.width);
  final maxRight = size.width - notificationDropdownWidth - 8;
  final right = preferredRight.clamp(8.0, maxRight < 8 ? 8.0 : maxRight);

  await showDialog<void>(
    context: buttonContext,
    barrierColor: Colors.black26,
    builder: (dialogContext) {
      return Stack(
        children: [
          Positioned(
            top: panelTop.clamp(8.0, size.height - 120),
            right: right,
            child: Material(
              elevation: 10,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              color: Theme.of(dialogContext).colorScheme.surface,
              child: SizedBox(
                width: notificationDropdownWidth,
                height: notificationDropdownMaxHeight,
                child: NotificationDropdownPanel(
                  onOpenItem: (item) {
                    Navigator.of(dialogContext).pop();
                    onOpenItem(buttonContext, item);
                  },
                  onViewAll: onViewAll == null
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop();
                          onViewAll();
                        },
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

/// Scrollable notification list used inside the dropdown panel.
class NotificationDropdownPanel extends ConsumerWidget {
  const NotificationDropdownPanel({
    super.key,
    required this.onOpenItem,
    this.onViewAll,
  });

  final void Function(NotificationItem item) onOpenItem;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notificationsAsync = ref.watch(notificationListProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.notifications,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  await ref.read(notificationsRepositoryProvider).markAllRead();
                },
                child: Text(l10n.markAllRead),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: AsyncBody(
            value: notificationsAsync,
            onRetry: () => ref.invalidate(notificationListProvider),
            skeletonRows: 4,
            data: (items) {
              if (items.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.notifications_none_outlined,
                          size: 40,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.noNotifications,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final dateStr = item.createdAt != null
                      ? BsDate.both(item.createdAt!)
                      : '—';
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: Icon(notificationIcon(item.type), size: 22),
                    title: Text(
                      notificationTitle(l10n, item),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: item.isUnread
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    subtitle: Text(dateStr),
                    trailing: item.isUnread
                        ? const Icon(
                            Icons.circle,
                            size: 8,
                            color: BsColors.primary,
                          )
                        : null,
                    onTap: () async {
                      if (item.isUnread) {
                        await ref
                            .read(notificationsRepositoryProvider)
                            .markRead(item.id);
                      }
                      onOpenItem(item);
                    },
                  );
                },
              );
            },
          ),
        ),
        if (onViewAll != null) ...[
          const Divider(height: 1),
          TextButton(onPressed: onViewAll, child: Text(l10n.viewAll)),
        ],
      ],
    );
  }
}
