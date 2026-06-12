import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app.dart';
import '../../core/l10n/app_localizations.dart';
import '../../features/notifications/providers.dart';
import '../../features/shell/logout_action.dart';

class WebTopBar extends ConsumerWidget {
  const WebTopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final unread = ref.watch(unreadNotificationCountProvider);

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          const Spacer(),
          SegmentedButton<String>(
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
              label: Text(unread > 9 ? '9+' : '$unread'),
              child: Icon(PhosphorIconsRegular.bell),
            ),
          ),
          const LogoutAction(),
        ],
      ),
    );
  }
}
