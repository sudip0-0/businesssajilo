import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/bs_snackbar.dart';
import '../../core/utils/app_prefs.dart';
import '../../data/repositories/member_settings_repository.dart';
import '../notifications/providers.dart';

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
  var _saving = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    var prefs = await NotificationMutePrefs.load();
    if (!mounted) return;
    setState(() {
      _prefs = prefs;
      _loaded = true;
    });
    try {
      final server = await ref
          .read(memberSettingsRepositoryProvider)
          .fetchMutedNotificationPrefs();
      if (server == null || !mounted) return;
      await server.save();
      if (!mounted) return;
      setState(() => _prefs = server);
      ref.invalidate(notificationMutePrefsProvider);
    } catch (_) {
      // Keep cached local prefs when the server is unreachable.
    }
  }

  Future<void> _set(NotificationMutePrefs next) async {
    if (_saving) return;
    final previous = _prefs;
    setState(() {
      _prefs = next;
      _saving = true;
    });
    await next.save();
    ref.invalidate(notificationMutePrefsProvider);
    try {
      await ref
          .read(memberSettingsRepositoryProvider)
          .updateMutedNotificationTypes(muted: next.mutedTypes);
    } catch (_) {
      await previous.save();
      if (!mounted) return;
      setState(() => _prefs = previous);
      ref.invalidate(notificationMutePrefsProvider);
      showBsSnackBar(
        context,
        message: AppLocalizations.of(context).actionFailed,
        backgroundColor: BsColors.danger,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
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
          title: Text(l10n.muteDuesReminders),
          value: _prefs.dues,
          onChanged: _saving ? null : (v) => _set(_prefs.copyWith(dues: v)),
        ),
        SwitchListTile(
          title: Text(l10n.muteLowStockAlerts),
          value: _prefs.lowStock,
          onChanged: _saving ? null : (v) => _set(_prefs.copyWith(lowStock: v)),
        ),
      ],
    );
  }
}
