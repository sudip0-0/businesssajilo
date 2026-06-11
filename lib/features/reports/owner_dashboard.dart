import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/layout/adaptive_scaffold.dart';
import '../../core/theme/app_theme.dart';
import '../auth/providers/auth_provider.dart';
import 'dues_aging_screen.dart';
import 'providers.dart';
import 'sales_bar_chart.dart';
import 'sales_summary_screen.dart';
import 'stock_valuation_screen.dart';

typedef DashboardStat = ({IconData icon, String label, String value, VoidCallback? onTap});

class OwnerDashboard extends ConsumerWidget {
  const OwnerDashboard({
    super.key,
    required this.stats,
    this.onOrdersTap,
  });

  final List<DashboardStat> stats;
  final VoidCallback? onOrdersTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(authProvider).value;
    final name = session?.member?.displayName ?? '';
    final wide = isWideLayout(context);
    final last7Async = ref.watch(last7DaySalesProvider);

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
          crossAxisCount: wide ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: stats
              .map(
                (s) => Card(
                  child: InkWell(
                    onTap: s.onTap,
                    borderRadius: BorderRadius.circular(12),
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
                ),
              )
              .toList(),
        ),
        if (wide) ...[
          const SizedBox(height: 24),
          Text(l10n.last7DaysSales,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          last7Async.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const SizedBox.shrink(),
            data: (points) => SalesBarChart(points: points),
          ),
        ],
        const SizedBox(height: 16),
        Text(l10n.viewReport, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionChip(
              avatar: const Icon(Icons.trending_up, size: 18),
              label: Text(l10n.salesSummary),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SalesSummaryScreen()),
              ),
            ),
            ActionChip(
              avatar: const Icon(Icons.hourglass_bottom, size: 18),
              label: Text(l10n.duesAging),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DuesAgingScreen()),
              ),
            ),
            ActionChip(
              avatar: const Icon(Icons.inventory, size: 18),
              label: Text(l10n.stockValuation),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StockValuationScreen(),
                ),
              ),
            ),
            if (onOrdersTap != null)
              ActionChip(
                avatar: const Icon(Icons.shopping_cart, size: 18),
                label: Text(l10n.pendingOrders),
                onPressed: onOrdersTap,
              ),
          ],
        ),
      ],
    );
  }
}
