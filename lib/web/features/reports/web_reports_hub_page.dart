import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/layout/bs_breakpoints.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/ui/bs_sales_line_chart.dart';
import '../../../core/utils/money.dart';
import '../../../domain/enums.dart';
import '../../../features/billing/providers.dart';
import '../../../features/customers/providers.dart';
import '../../../features/inventory/providers.dart';
import '../../../features/reports/providers.dart';
import '../../layout/web_bento_grid.dart';
import '../../theme/web_palette.dart';
import '../../ui/web_stat_tile.dart';
import '../web_page_scaffold.dart';
import 'widgets/aging_distribution_bar.dart';

class WebReportsHubPage extends ConsumerStatefulWidget {
  const WebReportsHubPage({super.key});

  @override
  ConsumerState<WebReportsHubPage> createState() => _WebReportsHubPageState();
}

class _WebReportsHubPageState extends ConsumerState<WebReportsHubPage> {
  bool _monthlyChart = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final chartRange = _monthlyChart
        ? ReportRange.last30Days
        : ReportRange.last7Days;
    final salesChart = ref.watch(salesDailyProvider(chartRange));
    final salesWeek = ref.watch(salesDailyProvider(ReportRange.week));
    final topProducts = ref.watch(topProductsProvider(ReportRange.week));
    final dues = ref.watch(duesAgingProvider);
    final stock = ref.watch(stockValuationProvider(false));
    final todaysSales = ref.watch(todaysSalesProvider);
    final pendingTodaysSales = ref.watch(pendingTodaysSalesProvider);
    final yesterdaysSales = ref.watch(yesterdaysSalesProvider);
    final totalDues = ref.watch(totalDuesProvider);
    final lowStock = ref.watch(lowStockCountProvider);

    return WebPageScaffold(
      title: l10n.reports,
      subtitle: l10n.reportOverview,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(salesDailyProvider(chartRange));
          ref.invalidate(salesDailyProvider(ReportRange.week));
          ref.invalidate(topProductsProvider(ReportRange.week));
          ref.invalidate(duesAgingProvider);
          ref.invalidate(stockValuationProvider(false));
          ref.invalidate(todaysSalesProvider);
          ref.invalidate(pendingTodaysSalesProvider);
          ref.invalidate(yesterdaysSalesProvider);
          ref.invalidate(totalDuesProvider);
          ref.invalidate(lowStockCountProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                    trend: _salesTrend(todaysSales, yesterdaysSales),
                    trendLabel: _salesTrendLabel(
                      todaysSales,
                      yesterdaysSales,
                      l10n,
                    ),
                    subtitle: pendingTodaysSales.when(
                      data: (d) => d > 0
                          ? l10n.pendingSyncSalesHint(
                              formatNpr(Paisa(d), showPaisa: false),
                            )
                          : null,
                      loading: () => null,
                      error: (_, _) => null,
                    ),
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
                    label: l10n.totalValuation,
                    value: stock.when(
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
                    icon: PhosphorIconsRegular.coins,
                    onTap: () => context.go('/owner/reports/stock'),
                  ),
                  WebStatTile(
                    label: l10n.lowStock,
                    value: lowStock.when(
                      data: (c) => '$c',
                      loading: () => '…',
                      error: (_, _) => '—',
                    ),
                    icon: PhosphorIconsRegular.package,
                    onTap: () => context.go('/owner/reports/stock?status=low'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              WebBentoTile(
                minHeight: 280,
                onTap: () => context.go('/owner/reports/sales'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.salesSummary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(width: 12),
                        SegmentedButton<bool>(
                          segments: [
                            ButtonSegment(
                              value: false,
                              label: Text(l10n.weekly),
                            ),
                            ButtonSegment(
                              value: true,
                              label: Text(l10n.monthly),
                            ),
                          ],
                          selected: {_monthlyChart},
                          onSelectionChanged: (s) {
                            setState(() => _monthlyChart = s.first);
                          },
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          PhosphorIconsRegular.arrowRight,
                          size: 16,
                          color: WebPalette.inkSoft,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    salesChart.when(
                      data: (points) => BsSalesLineChart(
                        points: points,
                        height: 200,
                        period: _monthlyChart
                            ? SalesChartPeriod.monthly
                            : SalesChartPeriod.weekly,
                      ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (_, _) => Text(l10n.loadingFailed),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= BsBreakpoints.desktop;
                  final salesCard = _ReportNavCard(
                    icon: PhosphorIconsRegular.chartLineUp,
                    title: l10n.salesSummary,
                    color: WebPalette.navy,
                    onTap: () => context.go('/owner/reports/sales'),
                    child: salesWeek.when(
                      data: (points) {
                        final total = points.fold<int>(
                          0,
                          (s, p) => s + p.totalSales,
                        );
                        final bills = points.fold<int>(
                          0,
                          (s, p) => s + p.billCount,
                        );
                        final top = topProducts.maybeWhen(
                          data: (rows) =>
                              rows.isEmpty ? null : rows.first.nameSnapshot,
                          orElse: () => null,
                        );
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formatNpr(Paisa(total), showPaisa: false),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${l10n.salesThisWeek} · $bills ${l10n.bills.toLowerCase()}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: WebPalette.inkSoft),
                            ),
                            if (top != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                '${l10n.topProductLabel}: $top',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ],
                        );
                      },
                      loading: () => const Text('…'),
                      error: (_, _) => Text(l10n.loadingFailed),
                    ),
                  );
                  final duesCard = _ReportNavCard(
                    icon: PhosphorIconsRegular.wallet,
                    title: l10n.duesAging,
                    color: WebPalette.danger,
                    onTap: () => context.go('/owner/reports/dues'),
                    child: dues.when(
                      data: (d) {
                        final total =
                            d.bucket0to30 + d.bucket31to60 + d.bucket60plus;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formatNpr(Paisa(total), showPaisa: false),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${d.customers.length} ${l10n.customers.toLowerCase()}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: WebPalette.inkSoft),
                            ),
                            const SizedBox(height: 10),
                            AgingDistributionBar(
                              bucket0to30: d.bucket0to30,
                              bucket31to60: d.bucket31to60,
                              bucket60plus: d.bucket60plus,
                              height: 10,
                              compact: true,
                              showLegend: false,
                            ),
                          ],
                        );
                      },
                      loading: () => const Text('…'),
                      error: (_, _) => Text(l10n.loadingFailed),
                    ),
                  );
                  final stockCard = _ReportNavCard(
                    icon: PhosphorIconsRegular.package,
                    title: l10n.stockValuation,
                    color: WebPalette.success,
                    onTap: () => context.go('/owner/reports/stock'),
                    child: stock.when(
                      data: (rows) {
                        final total = rows.fold<int>(
                          0,
                          (s, r) => s + r.valuation,
                        );
                        final low = rows.where((r) => r.isLowStock).length;
                        final out = rows
                            .where((r) => r.stockCached <= 0)
                            .length;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formatNpr(Paisa(total), showPaisa: false),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${l10n.lowStock}: $low · ${l10n.outOfStock}: $out',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: WebPalette.inkSoft),
                            ),
                          ],
                        );
                      },
                      loading: () => const Text('…'),
                      error: (_, _) => Text(l10n.loadingFailed),
                    ),
                  );

                  if (wide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: salesCard),
                        const SizedBox(width: 16),
                        Expanded(child: duesCard),
                        const SizedBox(width: 16),
                        Expanded(child: stockCard),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      salesCard,
                      const SizedBox(height: 12),
                      duesCard,
                      const SizedBox(height: 12),
                      stockCard,
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  WebTrendDirection? _salesTrend(
    AsyncValue<int> today,
    AsyncValue<int> yesterday,
  ) {
    final t = today.value;
    final y = yesterday.value;
    if (t == null || y == null) return null;
    if (t > y) return WebTrendDirection.up;
    if (t < y) return WebTrendDirection.down;
    return WebTrendDirection.neutral;
  }

  String? _salesTrendLabel(
    AsyncValue<int> today,
    AsyncValue<int> yesterday,
    AppLocalizations l10n,
  ) {
    final t = today.value;
    final y = yesterday.value;
    if (t == null || y == null || y == 0) return null;
    final pct = ((t - y).abs() / y * 100).round();
    return '$pct%';
  }
}

class _ReportNavCard extends StatelessWidget {
  const _ReportNavCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return WebBentoTile(
      minHeight: 160,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const Icon(
                PhosphorIconsRegular.caretRight,
                color: WebPalette.inkSoft,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
