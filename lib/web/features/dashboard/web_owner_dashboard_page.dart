import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/export/export_actions.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/report_range.dart';
import '../../../domain/enums.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/billing/providers.dart';
import '../../../features/customers/providers.dart';
import '../../../features/inventory/providers.dart';
import '../../../features/reports/providers.dart';
import '../web_page_scaffold.dart';
import '../../layout/web_bento_grid.dart';
import '../../../core/ui/bs_sales_line_chart.dart';
import '../../theme/web_palette.dart';
import '../../theme/web_typography.dart';
import '../../ui/web_search_field.dart';
import '../../ui/web_stat_tile.dart';
import '../../../core/testing/integration_keys.dart';
import 'sections/web_dashboard_recent_activity.dart';
import 'sections/web_dashboard_transactions_table.dart';

class WebOwnerDashboardPage extends ConsumerStatefulWidget {
  const WebOwnerDashboardPage({super.key});

  @override
  ConsumerState<WebOwnerDashboardPage> createState() =>
      _WebOwnerDashboardPageState();
}

class _WebOwnerDashboardPageState extends ConsumerState<WebOwnerDashboardPage> {
  bool _weeklyChart = true;

  Future<void> _refresh() async {
    ref.invalidate(last7DaySalesProvider);
    ref.invalidate(salesDailyProvider(ReportRange.last30Days));
    ref.invalidate(ownerDashboardStatsProvider);
    ref.invalidate(lowStockAlertsProvider);
    ref.invalidate(todaysBillsProvider);
    ref.invalidate(recentCustomersProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authProvider).value;
    final name = auth?.member?.displayName ?? '';
    final stats = ref.watch(ownerDashboardStatsProvider);
    final chartRange = _weeklyChart
        ? ReportRange.last7Days
        : ReportRange.last30Days;
    final chartData = ref.watch(salesDailyProvider(chartRange));
    final todaysBills = ref.watch(todaysBillsProvider);
    final lowStockAlerts = ref.watch(lowStockAlertsProvider);
    final recentCustomers = ref.watch(recentCustomersProvider);

    return WebPageScaffold(
      title: l10n.namasteGreeting(name),
      subtitle: l10n.dashboardTodaySummary,
      actions: [
        OutlinedButton(
          key: IntegrationKeys.dashboardAddProduct,
          onPressed: () => context.push('/owner/inventory/new'),
          child: Text(l10n.addProduct),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          key: IntegrationKeys.dashboardNewBill,
          onPressed: () => context.push('/owner/billing/new'),
          icon: const Icon(PhosphorIconsRegular.receipt, size: 18),
          label: Text(l10n.newBill),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WebBentoGrid(
                children: [
                  WebStatTile(
                    label: l10n.todaysSales,
                    value: stats.when(
                      data: (d) => d.todaySales == null
                          ? l10n.valueUnavailable
                          : formatNpr(Paisa(d.todaySales!), showPaisa: false),
                      loading: () => '…',
                      error: (_, _) => '—',
                    ),
                    icon: PhosphorIconsRegular.currencyDollar,
                    trend: stats.when(
                      data: (d) {
                        final pct = d.salesTrendPercent;
                        if (pct == null) return null;
                        return pct >= 0
                            ? WebTrendDirection.up
                            : WebTrendDirection.down;
                      },
                      loading: () => null,
                      error: (_, _) => null,
                    ),
                    trendLabel: stats.when(
                      data: (d) {
                        final pct = d.salesTrendPercent;
                        return pct == null
                            ? null
                            : '${pct.abs().toStringAsFixed(0)}%';
                      },
                      loading: () => null,
                      error: (_, _) => null,
                    ),
                    onTap: () => context.go('/owner/reports/sales'),
                  ),
                  WebStatTile(
                    label: l10n.totalDues,
                    value: stats.when(
                      data: (d) => d.totalDues == null
                          ? l10n.valueUnavailable
                          : formatNpr(Paisa(d.totalDues!), showPaisa: false),
                      loading: () => '…',
                      error: (_, _) => '—',
                    ),
                    icon: PhosphorIconsRegular.wallet,
                    onTap: () => context.go('/owner/reports/dues'),
                  ),
                  WebStatTile(
                    label: l10n.lowStock,
                    value: stats.when(
                      data: (d) => d.lowStockCount == null
                          ? l10n.valueUnavailable
                          : '${d.lowStockCount} ${l10n.products.toLowerCase()}',
                      loading: () => '…',
                      error: (_, _) => '—',
                    ),
                    icon: PhosphorIconsRegular.package,
                    subtitle: stats.when(
                      data: (d) =>
                          (d.lowStockCount ?? 0) > 0 ? l10n.reorderSoon : null,
                      loading: () => null,
                      error: (_, _) => null,
                    ),
                    onTap: () => context.go('/owner/reports/stock'),
                  ),
                  WebStatTile(
                    label: l10n.pendingOrders,
                    value: stats.when(
                      data: (d) => d.pendingOrders == null
                          ? l10n.valueUnavailable
                          : '${d.pendingOrders} ${l10n.orders.toLowerCase()}',
                      loading: () => '…',
                      error: (_, _) => '—',
                    ),
                    icon: PhosphorIconsRegular.shoppingCart,
                    trendLabel: stats.when(
                      data: (d) => (d.pendingOrders ?? 0) > 0
                          ? '${d.pendingOrders} NEW'
                          : null,
                      loading: () => null,
                      error: (_, _) => null,
                    ),
                    trend: stats.when(
                      data: (d) => (d.pendingOrders ?? 0) > 0
                          ? WebTrendDirection.neutral
                          : null,
                      loading: () => null,
                      error: (_, _) => null,
                    ),
                    onTap: () => context.go('/owner/orders'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 1024;
                  final chartSection = WebBentoTile(
                    minHeight: 320,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LayoutBuilder(
                          builder: (context, headerConstraints) {
                            final stackHeader =
                                headerConstraints.maxWidth < 480;
                            final titleBlock = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.salesPerformance,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                Text(
                                  _weeklyChart
                                      ? l10n.salesPerformanceSubtitle
                                      : l10n.salesPerformanceSubtitleMonthly,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: WebPalette.inkSoft),
                                ),
                              ],
                            );
                            final rangeToggle = SegmentedButton<bool>(
                              showSelectedIcon: false,
                              style: const ButtonStyle(
                                visualDensity: VisualDensity.compact,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              segments: [
                                ButtonSegment(
                                  value: true,
                                  label: Text(
                                    l10n.weekly,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                ButtonSegment(
                                  value: false,
                                  label: Text(
                                    l10n.monthly,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                              selected: {_weeklyChart},
                              onSelectionChanged: (s) =>
                                  setState(() => _weeklyChart = s.first),
                            );

                            if (stackHeader) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  titleBlock,
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: rangeToggle,
                                  ),
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(child: titleBlock),
                                rangeToggle,
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        chartData.when(
                          data: (data) {
                            final window = dateRangeFor(chartRange);
                            final filled = fillSalesDailyGaps(
                              points: data,
                              from: window.from,
                              to: window.to,
                            );
                            return BsSalesLineChart(
                              key: ValueKey(chartRange),
                              points: filled,
                              height: 220,
                              period: _weeklyChart
                                  ? SalesChartPeriod.weekly
                                  : SalesChartPeriod.monthly,
                            );
                          },
                          loading: () => const SizedBox(
                            height: 200,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (_, _) => const SizedBox(height: 200),
                        ),
                      ],
                    ),
                  );

                  final sideSection = Column(
                    children: [
                      WebBentoTile(
                        minHeight: 120,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.quickStockCheck,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 12),
                            WebSearchField(
                              hint: l10n.filterProducts,
                              onSubmitted: (q) {
                                final query = q.trim();
                                if (query.isEmpty) {
                                  context.go('/owner/inventory');
                                } else {
                                  context.go(
                                    '/owner/inventory?q=${Uri.encodeQueryComponent(query)}',
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      WebBentoTile(
                        minHeight: 180,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.recentActivity,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 160,
                              child: WebDashboardRecentActivity(
                                bills: todaysBills,
                                lowStockAlerts: lowStockAlerts,
                                recentCustomers: recentCustomers,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );

                  if (wide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: chartSection),
                        const SizedBox(width: 16),
                        Expanded(flex: 2, child: sideSection),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      chartSection,
                      const SizedBox(height: 16),
                      sideSection,
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              WebBentoTile(
                minHeight: 280,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text(
                          l10n.todaysTransactions,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        OutlinedButton.icon(
                          onPressed: todaysBills.hasValue
                              ? () => exportTodaysBillsCsv(ref, context)
                              : null,
                          icon: const Icon(
                            PhosphorIconsRegular.export,
                            size: 16,
                          ),
                          label: Text(l10n.export),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    todaysBills.when(
                      data: (bills) =>
                          WebDashboardTransactionsTable(bills: bills),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (_, _) => Text(l10n.loadingFailed),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.center,
                      child: TextButton.icon(
                        onPressed: () => context.go('/owner/billing'),
                        icon: const Icon(
                          PhosphorIconsRegular.arrowRight,
                          size: 16,
                        ),
                        label: Text(l10n.viewAllHistory),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: WebPalette.brass,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '© ${DateTime.now().year} ${l10n.appTitle.toUpperCase()} • ${l10n.madeForNepal.toUpperCase()}',
                      style: WebTypography.eyebrow(
                        color: WebPalette.inkFaint,
                      ).copyWith(fontSize: 10, letterSpacing: 1.3),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: WebPalette.brass,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
