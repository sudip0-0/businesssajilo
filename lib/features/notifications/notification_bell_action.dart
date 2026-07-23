import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';



import '../../core/l10n/app_localizations.dart';

import '../../core/layout/bs_touch_targets.dart';

import '../auth/providers/auth_provider.dart';

import 'notification_dropdown.dart';

import 'notification_navigation.dart';

import 'providers.dart';



class NotificationBellAction extends ConsumerWidget {

  const NotificationBellAction({super.key});



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    final l10n = AppLocalizations.of(context);

    final unreadAsync = ref.watch(unreadNotificationCountProvider);

    final unread = unreadAsync.value ?? 0;

    final badgeLabel = formatUnreadBadge(unread);

    final semanticLabel = unread > 0

        ? '${l10n.notifications}, $unread unread'

        : l10n.notifications;



    return Builder(

      builder: (buttonContext) {

        return Semantics(

          button: true,

          label: semanticLabel,

          child: ExcludeSemantics(

            child: BsTouchTargets.ensureMin(

              context: context,

              child: IconButton(

                tooltip: l10n.notifications,

                icon: Badge(

                  isLabelVisible: unread > 0,

                  label: Text(badgeLabel),

                  child: const Icon(Icons.notifications_outlined),

                ),

                onPressed: () {

                  final width = MediaQuery.sizeOf(buttonContext).width;

                  // 600px: no shared breakpoint — narrow enough for full-page list.
                  if (width < 600) {

                    context.push('/notifications');

                    return;

                  }

                  showNotificationDropdown(

                    buttonContext: buttonContext,

                    onOpenItem: (navContext, item) {

                      final role = ref.read(authProvider).value?.member?.role;

                      openNotificationTarget(navContext, item, role: role);

                    },

                    onViewAll: () => context.push('/notifications'),

                  );

                },

              ),

            ),

          ),

        );

      },

    );

  }

}

