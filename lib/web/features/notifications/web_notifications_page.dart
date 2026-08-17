import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/paginated_list_state.dart';
import '../../../core/utils/app_prefs.dart';
import '../../../core/utils/bs_date.dart';
import '../../../data/repositories/notifications_repository.dart';
import '../../../domain/models/notification_item.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/notifications/notification_labels.dart';
import '../../../features/notifications/providers.dart';
import '../../navigation/web_notification_navigation.dart';
import '../../theme/web_palette.dart';
import '../../ui/web_empty_state.dart';
import '../../ui/web_skeleton.dart';
import '../web_page_scaffold.dart';

class WebNotificationsPage extends ConsumerStatefulWidget {
  const WebNotificationsPage({super.key});

  @override
  ConsumerState<WebNotificationsPage> createState() =>
      _WebNotificationsPageState();
}

class _WebNotificationsPageState extends ConsumerState<WebNotificationsPage> {
  PaginatedListState<NotificationItem>? _pager;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initPager());
  }

  void _initPager() {
    _pager = PaginatedListState<NotificationItem>(
      loadPage: (offset, limit) => ref
          .read(notificationsRepositoryProvider)
          .list(offset: offset, limit: limit),
      onChanged: () {
        if (mounted) setState(() {});
      },
    )..attachScrollController(_scrollController);
    _pager!.refresh();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final prefs =
        ref.watch(notificationMutePrefsProvider).value ??
        const NotificationMutePrefs();
    final live = ref.watch(notificationListProvider).value ?? const [];
    final history = excludeMutedNotifications(_pager?.items ?? const [], prefs);
    final items = mergeNotificationPages(live: live, history: history);
    final loading = _pager?.loading == true && items.isEmpty;

    return WebPageScaffold(
      title: l10n.notifications,
      breadcrumbs: [l10n.notifications],
      actions: [
        TextButton(
          onPressed: () => ref.markAllNotificationsRead(),
          child: Text(l10n.markAllRead),
        ),
      ],
      body: loading
          ? const WebListSkeleton()
          : items.isEmpty
          ? WebEmptyState(
              message: l10n.noNotifications,
              icon: PhosphorIconsRegular.bell,
            )
          : DecoratedBox(
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
                  onRefresh: () async {
                    ref.invalidate(notificationListProvider);
                    ref.invalidate(unreadNotificationCountProvider);
                    await _pager?.refresh();
                  },
                  child: ListView.separated(
                    controller: _scrollController,
                    itemCount:
                        items.length + ((_pager?.hasMore ?? false) ? 1 : 0),
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: WebPalette.hairline),
                    itemBuilder: (context, index) {
                      if (index >= items.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return _WebNotificationRow(item: items[index]);
                    },
                  ),
                ),
              ),
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
            ref.invalidate(unreadNotificationCountProvider);
            ref.invalidate(notificationListProvider);
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
              : const Icon(
                  PhosphorIconsRegular.caretRight,
                  size: 16,
                  color: WebPalette.inkFaint,
                ),
        ),
      ),
    );
  }
}
