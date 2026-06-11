import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app.dart';
import '../../core/l10n/app_localizations.dart';
import '../onboarding/demo_data_seeder.dart';
import '../sync/pending_sync_screen.dart';

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
          onTap: _seeding ? null : () => _loadDemoData(context),
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: Text(l10n.aboutApp),
          subtitle: _version == null
              ? null
              : Text(l10n.appVersion(_version!)),
        ),
      ],
    );
  }

  Future<void> _loadDemoData(BuildContext context) async {
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
            child: Text(l10n.save),
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
}
