import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../auth/providers/auth_provider.dart';
import 'notification_dropdown.dart';
import 'notification_navigation.dart';
import 'providers.dart';

class NotificationBellAction extends ConsumerWidget {
  const NotificationBellAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final unread = ref.watch(unreadNotificationCountProvider);

    return Builder(
      builder: (buttonContext) {
        return IconButton(
          tooltip: l10n.notifications,
          icon: Badge(
            isLabelVisible: unread > 0,
            label: Text(unread > 9 ? '9+' : '$unread'),
            child: const Icon(Icons.notifications_outlined),
          ),
          onPressed: () {
            showNotificationDropdown(
              buttonContext: buttonContext,
              onOpenItem: (navContext, item) {
                final role = ref.read(authProvider).value?.member?.role;
                openNotificationTarget(navContext, item, role: role);
              },
            );
          },
        );
      },
    );
  }
}
