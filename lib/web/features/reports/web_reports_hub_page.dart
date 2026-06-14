import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../domain/enums.dart';
import '../../../features/billing/providers.dart';
import '../../../features/customers/providers.dart';
import '../../../features/inventory/providers.dart';
import '../../../features/reports/providers.dart';
import '../../layout/web_bento_grid.dart';
import '../../../core/ui/bs_sales_line_chart.dart';
import '../../ui/web_stat_tile.dart';
import '../web_page_scaffold.dart';

class WebReportsHubPage extends ConsumerWidget {
  const WebReportsHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final salesWeek = ref.watch(salesDailyProvider(ReportRange.week));
    final dues = ref.watch(duesAgingProvider);
    final stock = ref.watch(stockValuationProvider(false));
    final todaysSales = ref.watch(todaysSalesProvider);
    final totalDues = ref.watch(totalDuesProvider);
    final lowStock = ref.watch(lowStockCountProvider);

    return WebPageScaffold(
      title: l10n.reports,
      subtitle: l10n.reportOverview,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WebBentoGrid(
              children: [
                WebStatTile(
                  label: l10n.todaysSales,
                  value: todaysSales.when(
                    data: (d) => formatNpr(Paisa(d), showPaisa: false),
                    loading: () => '…',
                    error: (_, _) => '—',
                  ),
                  icon: PhosphorIconsRegular.chartLineUp,
                  onTap: () => context.go('/owner/reports/sales'),
                ),
                WebStatTile(
                  label: l10n.totalDues,
                  value: totalDues.when(
                    data: (d) => formatNpr(Paisa(d), showPaisa: false),
                    loading: () => '…',
                    error: (_, _) => '—',
                  ),
                  icon: PhosphorIconsRegular.wallet,
                  onTap: () => context.go('/owner/reports/dues'),
                ),
                WebStatTile(
                  label: l10n.lowStock,
                  value: lowStock.when(
                    data: (c) => '$c',
                    loading: () => '…',
                    error: (_, _) => '—',
                  ),
                  icon: PhosphorIconsRegular.package,
                  onTap: () => context.go('/owner/reports/stock'),
                ),
                WebStatTile(
                  label: l10n.duesAging,
                  value: dues.when(
                    data: (d) => formatNpr(
                      Paisa(d.bucket0to30 + d.bucket31to60 + d.bucket60plus),
                      showPaisa: false,
                    ),
                    loading: () => '…',
                    error: (_, _) => '—',
                  ),
                  icon: PhosphorIconsRegular.clockCountdown,
                  onTap: () => context.go('/owner/reports/dues'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 1024;
                final chart = WebBentoTile(
                  minHeight: 280,
                  onTap: () => context.go('/owner/reports/sales'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            l10n.salesSummary,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Spacer(),
                          Icon(
                            PhosphorIconsRegular.arrowRight,
                            size: 16,
                            color: BsColors.outline,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      salesWeek.when(
                        data: (points) => BsSalesLineChart(
                          points: points,
                          height: 200,
                        ),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (_, _) => Text(l10n.loadingFailed),
                      ),
                    ],
                  ),
                );

                final reports = Column(
                  children: [
                    _ReportNavCard(
                      icon: PhosphorIconsRegular.wallet,
                      title: l10n.duesAging,
                      subtitle: dues.when(
                        data: (d) =>
                            '${d.customers.length} ${l10n.customers.toLowerCase()}',
                        loading: () => '…',
                        error: (_, _) => '—',
                      ),
                      color: BsColors.danger,
                      onTap: () => context.go('/owner/reports/dues'),
                    ),
                    const SizedBox(height: 12),
                    _ReportNavCard(
                      icon: PhosphorIconsRegular.package,
                      title: l10n.stockValuation,
                      subtitle: stock.when(
                        data: (rows) {
                          final total = rows.fold<int>(
                            0,
                            (s, r) => s + r.valuation,
                          );
                          return formatNpr(Paisa(total), showPaisa: false);
                        },
                        loading: () => '…',
                        error: (_, _) => '—',
                      ),
                      color: BsColors.secondary,
                      onTap: () => context.go('/owner/reports/stock'),
                    ),
                  ],
                );

                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: chart),
                      const SizedBox(width: 16),
                      Expanded(flex: 2, child: reports),
                    ],
                  );
                }
                return Column(
                  children: [chart, const SizedBox(height: 16), reports],
                );
              },
            ),
          ],
        ),
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
    return WebBentoTile(
      minHeight: 100,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(BsRadii.lg),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: BsColors.outline,
                      ),
                ),
              ],
            ),
          ),
          Icon(PhosphorIconsRegular.caretRight, color: BsColors.outline),
        ],
      ),
    );
  }
}
