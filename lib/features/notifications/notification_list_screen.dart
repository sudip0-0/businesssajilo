import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/utils/app_prefs.dart';
import '../../core/utils/bs_date.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/list_skeleton.dart';
import '../../core/ui/paginated_list_state.dart';
import '../../data/repositories/notifications_repository.dart';
import '../../domain/models/notification_item.dart';
import '../auth/providers/auth_provider.dart';
import 'notification_labels.dart';
import 'notification_navigation.dart';
import 'providers.dart';

class NotificationListScreen extends ConsumerStatefulWidget {
  const NotificationListScreen({super.key});

  @override
  ConsumerState<NotificationListScreen> createState() =>
      _NotificationListScreenState();
}

class _NotificationListScreenState
    extends ConsumerState<NotificationListScreen> {
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifications),
        actions: [
          TextButton(
            onPressed: () => ref.markAllNotificationsRead(),
            child: Text(l10n.markAllRead),
          ),
        ],
      ),
      body: loading
          ? const ListSkeleton()
          : items.isEmpty
          ? EmptyState(
              icon: Icons.notifications_none_outlined,
              message: l10n.noNotifications,
            )
          : RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(notificationListProvider);
                ref.invalidate(unreadNotificationCountProvider);
                await _pager?.refresh();
              },
              child: ListView.separated(
                controller: _scrollController,
                itemCount: items.length + ((_pager?.hasMore ?? false) ? 1 : 0),
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  if (index >= items.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return _NotificationTile(item: items[index]);
                },
              ),
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
    final dateStr = item.createdAt != null ? BsDate.both(item.createdAt!) : '—';

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
          ref.invalidate(unreadNotificationCountProvider);
          ref.invalidate(notificationListProvider);
        }
        if (context.mounted) {
          final role = ref.read(authProvider).value?.member?.role;
          openNotificationTarget(context, item, role: role);
        }
      },
    );
  }
}
