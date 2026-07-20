import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../features/onboarding/demo_data_actions.dart';
import '../../../features/onboarding/onboarding_prefs.dart';
import '../../../features/settings/account_section.dart';
import '../../theme/web_tokens.dart';
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

  Future<void> _loadDemoData() => confirmAndSeedDemoData(
    context: context,
    ref: ref,
    onSeedingChanged: (seeding) => setState(() => _seeding = seeding),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final wide = !context.isWebCompact;

    final appearanceColumn = _SettingsColumn(
      title: l10n.language,
      icon: PhosphorIconsRegular.translate,
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
      ],
    );

    final dataColumn = _SettingsColumn(
      title: l10n.more,
      icon: PhosphorIconsRegular.database,
      children: [
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
          subtitle: _version == null ? null : Text(l10n.appVersion(_version!)),
        ),
        const AccountSettingsTiles(),
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
