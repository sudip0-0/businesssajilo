import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../features/onboarding/demo_data_seeder.dart';
import '../../../features/onboarding/onboarding_prefs.dart';
import '../../../features/sync/pending_sync_screen.dart';
import '../../layout/web_breakpoints.dart';
import '../web_page_scaffold.dart';

class WebSettingsPage extends ConsumerStatefulWidget {
  const WebSettingsPage({super.key});

  @override
  ConsumerState<WebSettingsPage> createState() => _WebSettingsPageState();
}

class _WebSettingsPageState extends ConsumerState<WebSettingsPage> {
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

  Future<void> _loadDemoData() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.loadDemoData),
        content: Text(l10n.loadDemoDataConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.loadDemoData),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _seeding = true);
    try {
      final result = await DemoDataSeeder(ref).seed();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            result == DemoSeedResult.loaded
                ? l10n.demoDataLoaded
                : l10n.demoDataSkipped,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final wide = !context.isWebCompact;

    final appearanceColumn = _SettingsColumn(
      title: l10n.theme,
      icon: PhosphorIconsRegular.palette,
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
              ref
                  .read(localeProvider.notifier)
                  .setLocale(Locale(selected.first));
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
      ],
    );

    final dataColumn = _SettingsColumn(
      title: l10n.more,
      icon: PhosphorIconsRegular.database,
      children: [
        ListTile(
          leading: Icon(PhosphorIconsRegular.cloudArrowUp),
          title: Text(l10n.pendingSyncItems),
          trailing: Icon(PhosphorIconsRegular.caretRight),
          onTap: () => context.push('/owner/settings/sync'),
        ),
        ListTile(
          leading: Icon(PhosphorIconsRegular.flask),
          title: Text(l10n.loadDemoData),
          subtitle: _seeding ? const LinearProgressIndicator() : null,
          onTap: _seeding ? null : _loadDemoData,
        ),
        ListTile(
          leading: Icon(PhosphorIconsRegular.compass),
          title: Text(l10n.replayTour),
          onTap: () async {
            final messenger = ScaffoldMessenger.of(context);
            await resetOnboarding();
            messenger.showSnackBar(
              SnackBar(content: Text(l10n.replayTourDone)),
            );
          },
        ),
        ListTile(
          leading: Icon(PhosphorIconsRegular.info),
          title: Text(l10n.aboutApp),
          subtitle: _version == null
              ? null
              : Text(l10n.appVersion(_version!)),
        ),
      ],
    );

    return WebPageScaffold(
      title: l10n.settings,
      breadcrumbs: [l10n.settings],
      body: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: appearanceColumn),
                const SizedBox(width: 24),
                Expanded(child: dataColumn),
              ],
            )
          : ListView(
              children: [
                appearanceColumn,
                const SizedBox(height: 24),
                dataColumn,
              ],
            ),
    );
  }
}

class _SettingsColumn extends StatelessWidget {
  const _SettingsColumn({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 10),
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
            const Divider(height: 1),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Full-page pending sync view linked from settings.
class WebPendingSyncPage extends StatelessWidget {
  const WebPendingSyncPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return WebPageScaffold(
      title: l10n.pendingSyncItems,
      breadcrumbs: [l10n.settings, l10n.pendingSyncItems],
      body: const PendingSyncScreen(),
    );
  }
}
