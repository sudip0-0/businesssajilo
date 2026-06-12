import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../features/notifications/providers.dart';
import '../../features/shell/logout_action.dart';
import '../theme/web_tokens.dart';

class WebTopBar extends ConsumerWidget {
  const WebTopBar({
    super.key,
    this.showMenuButton = false,
    this.onMenuPressed,
  });

  final bool showMenuButton;
  final VoidCallback? onMenuPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final unread = ref.watch(unreadNotificationCountProvider);
    final tokens = context.webTokens;

    return Container(
      height: tokens.topBarHeight,
      padding: EdgeInsets.symmetric(horizontal: tokens.pagePadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: BsColors.border)),
      ),
      child: Row(
        children: [
          if (showMenuButton)
            IconButton(
              tooltip: 'Menu',
              onPressed: onMenuPressed,
              icon: Icon(PhosphorIconsRegular.list, color: BsColors.primary),
            ),
          const Spacer(),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: 'en', label: Text(l10n.english)),
              ButtonSegment(value: 'ne', label: Text(l10n.nepali)),
            ],
            selected: {locale.languageCode},
            onSelectionChanged: (s) => ref
                .read(localeProvider.notifier)
                .setLocale(Locale(s.first)),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: l10n.notifications,
            onPressed: () => context.push('/notifications'),
            icon: Badge(
              isLabelVisible: unread > 0,
              backgroundColor: BsColors.secondary,
              label: Text(
                unread > 9 ? '9+' : '$unread',
                style: const TextStyle(fontSize: 10),
              ),
              child: Icon(PhosphorIconsRegular.bell, color: BsColors.outline),
            ),
          ),
          const LogoutAction(),
        ],
      ),
    );
  }
}
