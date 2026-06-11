import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../auth/providers/auth_provider.dart';

class RoleDashboard extends ConsumerWidget {
  const RoleDashboard({
    super.key,
    required this.stats,
  });

  final List<({IconData icon, String label, String value})> stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(authProvider).value;
    final name = session?.member?.displayName ?? '';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l10n.welcomeUser(name),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: MediaQuery.sizeOf(context).width > 600 ? 3 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: stats
              .map(
                (s) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(s.icon, color: BsColors.primary),
                        const Spacer(),
                        Text(
                          s.label,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.value,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
