import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/utils/app_prefs.dart';
import '../../data/repositories/member_settings_repository.dart';
import '../auth/providers/auth_provider.dart';

class NotificationPrefsSection extends ConsumerStatefulWidget {
  const NotificationPrefsSection({super.key});

  @override
  ConsumerState<NotificationPrefsSection> createState() =>
      _NotificationPrefsSectionState();
}

class _NotificationPrefsSectionState
    extends ConsumerState<NotificationPrefsSection> {
  NotificationMutePrefs _prefs = const NotificationMutePrefs();
  var _loaded = false;

  @override
  void initState() {
    super.initState();
    unawaited(
      NotificationMutePrefs.load().then((value) {
        if (!mounted) return;
        setState(() {
          _prefs = value;
          _loaded = true;
        });
      }),
    );
  }

  Future<void> _set(NotificationMutePrefs next) async {
    setState(() => _prefs = next);
    await next.save();
    final memberId = ref.read(authProvider).value?.member?.id;
    if (memberId == null) return;
    try {
      await ref
          .read(memberSettingsRepositoryProvider)
          .updateMutedNotificationTypes(muted: next.mutedTypes);
    } catch (_) {
      // Local prefs still apply; server mute is best-effort.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!_loaded) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SwitchListTile(
          title: Text(l10n.muteChatNotifications),
          value: _prefs.chat,
          onChanged: (v) => _set(_prefs.copyWith(chat: v)),
        ),
        SwitchListTile(
          title: Text(l10n.muteDuesReminders),
          value: _prefs.dues,
          onChanged: (v) => _set(_prefs.copyWith(dues: v)),
        ),
        SwitchListTile(
          title: Text(l10n.muteLowStockAlerts),
          value: _prefs.lowStock,
          onChanged: (v) => _set(_prefs.copyWith(lowStock: v)),
        ),
      ],
    );
  }
}
