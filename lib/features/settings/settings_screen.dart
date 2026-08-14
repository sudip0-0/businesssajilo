import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/ui/locale_toggle.dart';
import '../../core/ui/sync_badge.dart';
import '../../core/utils/bs_date.dart';
import '../../data/sync/sync_providers.dart';
import '../auth/providers/auth_provider.dart';
import '../onboarding/demo_data_actions.dart';
import '../sync/pending_sync_screen.dart';
import 'account_section.dart';
import 'business_profile_section.dart';
import 'notification_prefs_section.dart';
import 'subscription_plan_tile.dart';

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

    return ListView(
      children: [
        ListTile(
          title: Text(l10n.language),
          subtitle: Text(
            Localizations.localeOf(context).languageCode == 'ne'
                ? l10n.nepali
                : l10n.english,
          ),
          trailing: const FittedBox(
            fit: BoxFit.scaleDown,
            child: LocaleToggle(compact: true),
          ),
        ),
        const Divider(height: 1),
        const _SyncStatusTile(),
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
        const Divider(height: 1),
        const BusinessProfileSection(),
        const Divider(height: 1),
        const NotificationPrefsSection(),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: Text(l10n.aboutApp),
          subtitle: _version == null ? null : Text(l10n.appVersion(_version!)),
        ),
        const SubscriptionPlanTile(),
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

class _SyncStatusTile extends ConsumerWidget {
  const _SyncStatusTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final statusAsync = ref.watch(syncStatusProvider);

    void openPending() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PendingSyncScreen()),
      );
    }

    return statusAsync.when(
      loading: () => ListTile(
        leading: const Icon(Icons.cloud_sync_outlined),
        title: Text(l10n.syncStatus),
        trailing: const Icon(Icons.chevron_right),
        onTap: openPending,
      ),
      error: (_, _) => ListTile(
        leading: const Icon(Icons.cloud_off),
        title: Text(l10n.offline),
        trailing: const Icon(Icons.chevron_right),
        onTap: openPending,
      ),
      data: (status) {
        final appearance = SyncBadgeAppearance.from(
          l10n: l10n,
          state: status.state,
          pendingCount: status.pendingCount,
        );
        final lastSync = status.lastSuccessAt;
        return ListTile(
          leading: Icon(appearance.icon, color: appearance.color),
          title: Text(appearance.label),
          subtitle: lastSync == null
              ? null
              : Text(l10n.lastSyncAt(BsDate.both(lastSync))),
          trailing: const Icon(Icons.chevron_right),
          onTap: openPending,
        );
      },
    );
  }
}
