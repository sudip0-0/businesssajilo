import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app.dart';
import '../../core/l10n/app_localizations.dart';
import '../auth/providers/auth_provider.dart';
import '../onboarding/demo_data_actions.dart';
import '../onboarding/onboarding_prefs.dart';
import '../sync/pending_sync_screen.dart';
import 'account_section.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String? _version;
  bool _seeding = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _version = info.version);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return ListView(
      children: [
        ListTile(
          title: Text(l10n.language),
          subtitle: Text(
            locale.languageCode == 'ne' ? l10n.nepali : l10n.english,
          ),
          trailing: SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'en', label: Text(l10n.english)),
              ButtonSegment(value: 'ne', label: Text(l10n.nepali)),
            ],
            selected: {locale.languageCode},
            onSelectionChanged: (selected) {
              final code = selected.first;
              ref.read(localeProvider.notifier).setLocale(Locale(code));
            },
          ),
        ),
        ListTile(
          title: Text(l10n.theme),
          subtitle: Text(switch (themeMode) {
            ThemeMode.system => l10n.themeSystem,
            ThemeMode.light => l10n.themeLight,
            ThemeMode.dark => l10n.themeDark,
          }),
          trailing: SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text(l10n.themeSystem),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: const Icon(Icons.light_mode_outlined),
                label: Text(l10n.themeLight),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: const Icon(Icons.dark_mode_outlined),
                label: Text(l10n.themeDark),
              ),
            ],
            showSelectedIcon: false,
            selected: {themeMode},
            onSelectionChanged: (selected) {
              ref.read(themeModeProvider.notifier).setMode(selected.first);
            },
          ),
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.cloud_sync_outlined),
          title: Text(l10n.pendingSyncItems),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PendingSyncScreen()),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.dataset_outlined),
          title: Text(l10n.loadDemoData),
          subtitle: _seeding ? const LinearProgressIndicator() : null,
          onTap: _seeding
              ? null
              : () => confirmAndSeedDemoData(
                  context: context,
                  ref: ref,
                  onSeedingChanged: (seeding) =>
                      setState(() => _seeding = seeding),
                ),
        ),
        ListTile(
          leading: const Icon(Icons.replay_outlined),
          title: Text(l10n.replayTour),
          onTap: () async {
            final messenger = ScaffoldMessenger.of(context);
            final message = l10n.replayTourDone;
            await resetOnboarding();
            messenger.showSnackBar(SnackBar(content: Text(message)));
          },
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: Text(l10n.aboutApp),
          subtitle: _version == null ? null : Text(l10n.appVersion(_version!)),
        ),
        const AccountSettingsTiles(),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.logout),
          title: Text(l10n.logout),
          onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(l10n.logout),
                content: Text(l10n.logoutConfirm),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(l10n.cancel),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(l10n.logout),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              await ref.read(authProvider.notifier).signOut();
            }
          },
        ),
      ],
    );
  }
}
