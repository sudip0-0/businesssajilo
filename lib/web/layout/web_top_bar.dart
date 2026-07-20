import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/ui/locale_toggle.dart';
import '../../core/utils/role_label.dart';
import '../../domain/enums.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/notifications/notification_dropdown.dart';
import '../../features/notifications/providers.dart';
import '../../features/settings/account_section.dart';
import '../../features/shell/logout_action.dart';
import '../navigation/web_notification_navigation.dart';
import '../router/web_role_routes.dart';
import '../theme/web_palette.dart';
import '../theme/web_tokens.dart';

class WebTopBar extends ConsumerWidget {
  const WebTopBar({super.key, this.showMenuButton = false, this.onMenuPressed});

  final bool showMenuButton;
  final VoidCallback? onMenuPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final unread = ref.watch(unreadNotificationCountProvider);
    final tokens = context.webTokens;
    final auth = ref.watch(authProvider).value;
    final name = auth?.member?.displayName ?? '';
    final role = auth?.member?.role;
    final compact = context.isWebCompact;
    final path = GoRouterState.of(context).uri.path;
    final isOwner = path.startsWith('/owner') || role == Role.owner;

    return Container(
      height: tokens.topBarHeight,
      padding: EdgeInsets.symmetric(horizontal: tokens.pagePadding),
      decoration: const BoxDecoration(
        color: WebPalette.card,
        border: Border(bottom: BorderSide(color: WebPalette.hairline)),
      ),
      child: Row(
        children: [
          if (showMenuButton)
            IconButton(
              tooltip: l10n.openMenu,
              onPressed: onMenuPressed,
              icon: const Icon(
                PhosphorIconsRegular.list,
                color: WebPalette.navy,
              ),
            ),
          const Spacer(),
          const LocaleToggle(compact: true),
          const SizedBox(width: 4),
          Builder(
            builder: (buttonContext) {
              return IconButton(
                tooltip: l10n.notifications,
                onPressed: () {
                  final memberRole =
                      ref.read(authProvider).value?.member?.role;
                  showNotificationDropdown(
                    buttonContext: buttonContext,
                    onOpenItem: (navContext, item) {
                      openWebNotificationTarget(
                        navContext,
                        item,
                        role: ref.read(authProvider).value?.member?.role,
                      );
                    },
                    onViewAll: memberRole == null
                        ? null
                        : () => context.go(
                            '${webRoleBasePath(memberRole)}/notifications',
                          ),
                  );
                },
                icon: Badge(
                  isLabelVisible: unread > 0,
                  backgroundColor: WebPalette.brass,
                  label: Text(
                    unread > 9 ? '9+' : '$unread',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Icon(
                    PhosphorIconsRegular.bell,
                    color: WebPalette.inkSoft,
                    size: 21,
                  ),
                ),
              );
            },
          ),
          if (isOwner)
            IconButton(
              tooltip: l10n.settings,
              onPressed: () => context.go('/owner/settings'),
              icon: const Icon(
                PhosphorIconsRegular.gear,
                color: WebPalette.inkSoft,
                size: 21,
              ),
            )
          else
            const AccountAction(),
          if (!compact && name.isNotEmpty) ...[
            const SizedBox(width: 10),
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: WebPalette.navyWash,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: WebPalette.navy.withValues(alpha: 0.14),
                ),
              ),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: WebPalette.navy,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
            ),
            const SizedBox(width: 9),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.split(' ').first,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: WebPalette.ink),
                ),
                Text(
                  role != null ? roleLabel(l10n, role) : '',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: WebPalette.inkFaint,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ],
          const LogoutAction(),
        ],
      ),
    );
  }
}
