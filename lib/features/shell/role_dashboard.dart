import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/bs_stat_tile.dart';
import '../auth/providers/auth_provider.dart';

class DashboardStat {
  const DashboardStat({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final String? subtitle;
}

class RoleDashboard extends ConsumerWidget {
  const RoleDashboard({super.key, required this.stats, this.cta});

  final List<DashboardStat> stats;
  final Widget? cta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(authProvider).value;
    final name = session?.member?.displayName ?? '';
    final wide = MediaQuery.sizeOf(context).width > 600;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text(
          l10n.namasteGreeting(name),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: BsColors.textCharcoal,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.dashboardTodaySummary,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: BsColors.outline),
        ),
        const SizedBox(height: 16),
        if (cta != null) ...[cta!, const SizedBox(height: 16)],
        GridView.count(
          crossAxisCount: wide ? 3 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: wide ? 1.5 : 1.15,
          children: stats
              .map(
                (s) => BsStatTile(
                  compact: !wide,
                  label: s.label,
                  value: s.value,
                  icon: s.icon,
                  subtitle: s.subtitle,
                  onTap: s.onTap,
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
