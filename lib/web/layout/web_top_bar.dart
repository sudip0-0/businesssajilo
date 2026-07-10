import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/utils/role_label.dart';
import '../../domain/enums.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/notifications/providers.dart';
import '../../features/settings/account_section.dart';
import '../../features/shell/logout_action.dart';
import '../theme/web_tokens.dart';
import '../../core/ui/locale_toggle.dart';

class WebTopBar extends ConsumerWidget {
  const WebTopBar({super.key, this.showMenuButton = false, this.onMenuPressed});

  final bool showMenuButton;
  final VoidCallback? onMenuPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
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
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          if (showMenuButton)
            IconButton(
              tooltip: 'Menu',
              onPressed: onMenuPressed,
              icon: Icon(PhosphorIconsRegular.list, color: scheme.primary),
            ),
          const Spacer(),
          const LocaleToggle(compact: true),
          const SizedBox(width: 8),
          IconButton(
            tooltip: l10n.notifications,
            onPressed: () => context.push('/notifications'),
            icon: Badge(
              isLabelVisible: unread > 0,
              backgroundColor: scheme.secondary,
              label: Text(
                unread > 9 ? '9+' : '$unread',
                style: TextStyle(fontSize: 10, color: scheme.onSecondary),
              ),
              child: Icon(
                PhosphorIconsRegular.bell,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          if (isOwner)
            IconButton(
              tooltip: l10n.settings,
              onPressed: () => context.go('/owner/settings'),
              icon: Icon(
                PhosphorIconsRegular.gear,
                color: scheme.onSurfaceVariant,
              ),
            )
          else
            const AccountAction(),
          if (!compact && name.isNotEmpty) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: scheme.primary.withValues(alpha: 0.12),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.split(' ').first,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Text(
                  role != null ? roleLabel(l10n, role) : '',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 0.5,
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
