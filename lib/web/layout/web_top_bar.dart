import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/layout/bs_touch_targets.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/locale_toggle.dart';
import '../../core/utils/role_label.dart';
import '../../domain/enums.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/notifications/notification_dropdown.dart';
import '../../features/notifications/providers.dart';
import '../../features/search/global_search_sheet.dart';
import '../../features/settings/account_section.dart';
import '../../features/shell/logout_action.dart';
import '../navigation/web_notification_navigation.dart';
import '../router/web_role_routes.dart';
import '../theme/web_palette.dart';
import '../theme/web_tokens.dart';
import '../theme/web_typography.dart';

class WebTopBar extends ConsumerWidget {
  const WebTopBar({
    super.key,
    this.showMenuButton = false,
    this.onMenuPressed,
    this.onOpenShortcuts,
  });

  final bool showMenuButton;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onOpenShortcuts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final unread = ref.watch(unreadNotificationCountProvider).value ?? 0;
    final badgeLabel = formatUnreadBadge(unread);
    final tokens = context.webTokens;
    final auth = ref.watch(authProvider).value;
    final name = auth?.member?.displayName ?? '';
    final role = auth?.member?.role;
    final compact = context.isWebCompact;
    final path = GoRouterState.of(context).uri.path;
    final isOwner = path.startsWith('/owner') || role == Role.owner;
    final showSearch = isOwner || role == Role.sales || role == Role.warehouse;

    return Semantics(
      identifier: 'web_top_bar',
      container: true,
      explicitChildNodes: true,
      child: FocusTraversalGroup(
        child: Container(
          height: tokens.topBarHeight,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : tokens.pagePadding,
          ),
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
              if (!compact && showSearch) ...[
                _SearchTriggerPill(
                  label: l10n.globalSearch,
                  tooltip: '${l10n.globalSearch} (Ctrl+K / /)',
                  onTap: () => showGlobalSearch(context, ref),
                ),
              ],
              const Spacer(),
              if (compact && showSearch)
                IconButton(
                  tooltip: '${l10n.globalSearch} (Ctrl+K)',
                  onPressed: () => showGlobalSearch(context, ref),
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    PhosphorIconsRegular.magnifyingGlass,
                    color: WebPalette.navy,
                    size: 20,
                  ),
                ),
              if (!compact && onOpenShortcuts != null)
                IconButton(
                  tooltip: '${l10n.keyboardShortcuts} (?)',
                  onPressed: onOpenShortcuts,
                  icon: const Icon(
                    PhosphorIconsRegular.keyboard,
                    color: WebPalette.inkSoft,
                    size: 20,
                  ),
                ),
              const LocaleToggle(compact: true),
              SizedBox(width: compact ? 2 : 4),
              Builder(
                builder: (buttonContext) {
                  final semanticLabel = unread > 0
                      ? '${l10n.notifications}, $unread unread'
                      : l10n.notifications;
                  return Tooltip(
                    message: semanticLabel,
                    excludeFromSemantics: true,
                    child: MergeSemantics(
                      child: Semantics(
                        label: semanticLabel,
                        child: BsTouchTargets.ensureMin(
                          context: context,
                          child: IconButton(
                            onPressed: () {
                              final memberRole = ref
                                  .read(authProvider)
                                  .value
                                  ?.member
                                  ?.role;
                              showNotificationDropdown(
                                buttonContext: buttonContext,
                                onOpenItem: (navContext, item) {
                                  openWebNotificationTarget(
                                    navContext,
                                    item,
                                    role: ref
                                        .read(authProvider)
                                        .value
                                        ?.member
                                        ?.role,
                                  );
                                },
                                onViewAll: memberRole == null
                                    ? null
                                    : () => context.go(
                                        '${webRoleBasePath(memberRole)}/notifications',
                                      ),
                              );
                            },
                            icon: ExcludeSemantics(
                              child: Badge(
                                isLabelVisible: unread > 0,
                                backgroundColor:
                                    BsSemanticColors.notificationUnread,
                                label: Text(
                                  badgeLabel,
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
                            ),
                          ),
                        ),
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
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.split(' ').first,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.labelLarge?.copyWith(color: WebPalette.ink),
                      ),
                      Text(
                        role != null ? roleLabel(l10n, role) : '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: WebPalette.inkFaint,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const LogoutAction(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchTriggerPill extends StatelessWidget {
  const _SearchTriggerPill({
    required this.label,
    required this.tooltip,
    required this.onTap,
  });

  final String label;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        label: label,
        child: Material(
          color: WebPalette.paper,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            hoverColor: WebPalette.paperDeep,
            child: Container(
              height: 36,
              constraints: const BoxConstraints(minWidth: 196, maxWidth: 280),
              padding: const EdgeInsets.symmetric(horizontal: 11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: WebPalette.hairline),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    PhosphorIconsRegular.magnifyingGlass,
                    size: 16,
                    color: WebPalette.inkSoft,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: WebPalette.inkSoft,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ExcludeSemantics(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: WebPalette.cardBright,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: WebPalette.hairlineStrong),
                      ),
                      child: Text(
                        'Ctrl K',
                        style: WebTypography.mono(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: WebPalette.inkSoft,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
