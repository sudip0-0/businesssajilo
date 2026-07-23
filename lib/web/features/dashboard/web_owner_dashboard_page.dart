import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/layout/bs_breakpoints.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/ui/error_state.dart';
import '../../../domain/enums.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/billing/providers.dart';
import '../../../features/customers/providers.dart';
import '../../../features/inventory/providers.dart';
import '../../../features/reports/dashboard/dashboard_invalidation.dart';
import '../../../features/reports/providers.dart';
import '../../../features/reports/report_export_actions.dart';
import '../../../core/testing/integration_keys.dart';
import '../../layout/web_bento_grid.dart';
import '../../theme/web_palette.dart';
import '../../theme/web_typography.dart';
import '../../ui/web_search_field.dart';
import '../web_page_scaffold.dart';
import 'sections/web_dashboard_kpi_grid.dart';
import 'sections/web_dashboard_recent_activity.dart';
import 'sections/web_dashboard_sales_chart.dart';
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
    invalidateOwnerDashboardWidget(ref);
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
              WebDashboardKpiGrid(
                stats: stats,
                onRetry: () => ref.invalidate(ownerDashboardStatsProvider),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= BsBreakpoints.desktop;
                  final chartSection = WebDashboardSalesChart(
                    weeklyChart: _weeklyChart,
                    chartData: chartData,
                    chartRange: chartRange,
                    onRangeChanged: (v) => setState(() => _weeklyChart = v),
                    onRetry: () =>
                        ref.invalidate(salesDailyProvider(chartRange)),
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
                                onRetry: _refresh,
                              ),                            ),
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
                      error: (_, _) => ErrorState(
                        message: l10n.loadingFailed,
                        onRetry: () => ref.invalidate(todaysBillsProvider),
                      ),                    ),
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
