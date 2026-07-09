import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/bs_sales_line_chart.dart';
import '../../core/ui/bs_stat_tile.dart';
import '../../core/utils/money.dart';
import '../../domain/enums.dart';
import '../billing/providers.dart';
import '../customers/providers.dart';
import '../inventory/providers.dart';
import 'dues_aging_screen.dart';
import 'providers.dart';
import 'sales_summary_screen.dart';
import 'stock_valuation_screen.dart';

class ReportsHubScreen extends ConsumerWidget {
  const ReportsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final salesWeek = ref.watch(salesDailyProvider(ReportRange.week));
    final dues = ref.watch(duesAgingProvider);
    final stock = ref.watch(stockValuationProvider(false));
    final todaysSales = ref.watch(todaysSalesProvider);
    final totalDues = ref.watch(totalDuesProvider);
    final lowStock = ref.watch(lowStockCountProvider);
    final wide = MediaQuery.sizeOf(context).width >= 600;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(salesDailyProvider(ReportRange.week));
        ref.invalidate(duesAgingProvider);
        ref.invalidate(stockValuationProvider(false));
        ref.invalidate(todaysSalesProvider);
        ref.invalidate(totalDuesProvider);
        ref.invalidate(lowStockCountProvider);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.reportOverview,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: BsColors.outline),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: wide ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: wide ? 1.5 : 1.15,
            children: [
              BsStatTile(
                compact: !wide,
                label: l10n.todaysSales,
                value: todaysSales.when(
                  data: (d) => formatNpr(Paisa(d), showPaisa: false),
                  loading: () => '…',
                  error: (_, _) => '—',
                ),
                icon: Icons.trending_up,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SalesSummaryScreen()),
                ),
              ),
              BsStatTile(
                compact: !wide,
                label: l10n.totalDues,
                value: totalDues.when(
                  data: (d) => formatNpr(Paisa(d), showPaisa: false),
                  loading: () => '…',
                  error: (_, _) => '—',
                ),
                icon: Icons.account_balance_wallet_outlined,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DuesAgingScreen()),
                ),
              ),
              BsStatTile(
                compact: !wide,
                label: l10n.lowStock,
                value: lowStock.when(
                  data: (c) => '$c',
                  loading: () => '…',
                  error: (_, _) => '—',
                ),
                icon: Icons.inventory_2_outlined,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const StockValuationScreen(lowStockOnly: true),
                  ),
                ),
              ),
              BsStatTile(
                compact: !wide,
                label: l10n.duesAging,
                value: dues.when(
                  data: (d) => formatNpr(
                    Paisa(d.bucket0to30 + d.bucket31to60 + d.bucket60plus),
                    showPaisa: false,
                  ),
                  loading: () => '…',
                  error: (_, _) => '—',
                ),
                icon: Icons.hourglass_bottom_outlined,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DuesAgingScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.salesSummary,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  salesWeek.when(
                    data: (points) => BsSalesLineChart(points: points),
                    loading: () => const LinearProgressIndicator(),
                    error: (_, _) => Text(l10n.loadingFailed),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _ReportNavCard(
            icon: Icons.trending_up,
            title: l10n.salesSummary,
            subtitle: l10n.salesPerformanceSubtitle,
            color: BsColors.primary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SalesSummaryScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _ReportNavCard(
            icon: Icons.hourglass_bottom_outlined,
            title: l10n.duesAging,
            subtitle: dues.when(
              data: (d) =>
                  '${d.customers.length} ${l10n.customers.toLowerCase()}',
              loading: () => '…',
              error: (_, _) => '—',
            ),
            color: BsColors.danger,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DuesAgingScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _ReportNavCard(
            icon: Icons.inventory_2_outlined,
            title: l10n.stockValuation,
            subtitle: stock.when(
              data: (rows) {
                final total = rows.fold<int>(0, (s, r) => s + r.valuation);
                return formatNpr(Paisa(total), showPaisa: false);
              },
              loading: () => '…',
              error: (_, _) => '—',
            ),
            color: BsColors.secondary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StockValuationScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportNavCard extends StatelessWidget {
  const _ReportNavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(BsRadii.lg),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
