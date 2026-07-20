import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/layout/adaptive_scaffold.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/bill_status_chip.dart';
import '../../core/ui/bs_sales_line_chart.dart';
import '../../core/ui/bs_stat_tile.dart';
import '../../core/utils/money.dart';
import '../../core/utils/report_range.dart';
import '../../domain/enums.dart';
import '../../domain/models/bill.dart';
import '../../domain/models/product.dart';
import '../auth/providers/auth_provider.dart';
import '../billing/providers.dart';
import '../inventory/providers.dart';
import 'dues_aging_screen.dart';
import 'providers.dart';
import 'sales_summary_screen.dart';
import 'stock_valuation_screen.dart';

class OwnerDashboard extends ConsumerStatefulWidget {
  const OwnerDashboard({super.key, this.onOrdersTap});

  final VoidCallback? onOrdersTap;

  @override
  ConsumerState<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends ConsumerState<OwnerDashboard> {
  bool _weeklyChart = true;

  Future<void> _refresh() async {
    ref.invalidate(last7DaySalesProvider);
    ref.invalidate(salesDailyProvider(ReportRange.last30Days));
    ref.invalidate(ownerDashboardStatsProvider);
    ref.invalidate(lowStockAlertsProvider);
    ref.invalidate(todaysBillsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(authProvider).value;
    final name = session?.member?.displayName ?? '';
    final wide = isWideLayout(context);
    final stats = ref.watch(ownerDashboardStatsProvider);
    final chartRange = _weeklyChart
        ? ReportRange.last7Days
        : ReportRange.last30Days;
    final chartData = ref.watch(salesDailyProvider(chartRange));
    final todaysBills = ref.watch(todaysBillsProvider);
    final lowStockAlerts = ref.watch(lowStockAlertsProvider);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
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
                value: stats.when(
                  data: (d) => formatNpr(Paisa(d.todaySales), showPaisa: false),
                  loading: () => '…',
                  error: (_, _) => l10n.loadingFailed,
                ),
                icon: Icons.payments_outlined,
                trend: stats.when(
                  data: (d) {
                    final pct = d.salesTrendPercent;
                    if (pct == null) return null;
                    return pct >= 0
                        ? BsTrendDirection.up
                        : BsTrendDirection.down;
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
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SalesSummaryScreen()),
                ),
              ),
              BsStatTile(
                compact: !wide,
                label: l10n.totalDues,
                value: stats.when(
                  data: (d) => formatNpr(Paisa(d.totalDues), showPaisa: false),
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
                value: stats.when(
                  data: (d) => '${d.lowStockCount}',
                  loading: () => '…',
                  error: (_, _) => '—',
                ),
                icon: Icons.inventory_2_outlined,
                subtitle: stats.when(
                  data: (d) => d.lowStockCount > 0 ? l10n.reorderSoon : null,
                  loading: () => null,
                  error: (_, _) => null,
                ),
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
                label: l10n.pendingOrders,
                value: stats.when(
                  data: (d) => '${d.pendingOrders}',
                  loading: () => '…',
                  error: (_, _) => '—',
                ),
                icon: Icons.shopping_cart_outlined,
                trendLabel: stats.when(
                  data: (d) =>
                      d.pendingOrders > 0 ? '${d.pendingOrders} NEW' : null,
                  loading: () => null,
                  error: (_, _) => null,
                ),
                trend: stats.when(
                  data: (d) =>
                      d.pendingOrders > 0 ? BsTrendDirection.neutral : null,
                  loading: () => null,
                  error: (_, _) => null,
                ),
                onTap: widget.onOrdersTap,
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
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.salesPerformance,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              _weeklyChart
                                  ? l10n.salesPerformanceSubtitle
                                  : l10n.salesPerformanceSubtitleMonthly,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: BsColors.outline),
                            ),
                          ],
                        ),
                      ),
                      SegmentedButton<bool>(
                        showSelectedIcon: false,
                        segments: [
                          ButtonSegment(value: true, label: Text(l10n.weekly)),
                          ButtonSegment(
                            value: false,
                            label: Text(l10n.monthly),
                          ),
                        ],
                        selected: {_weeklyChart},
                        onSelectionChanged: (s) =>
                            setState(() => _weeklyChart = s.first),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  chartData.when(
                    data: (points) {
                      final window = dateRangeFor(chartRange);
                      final filled = fillSalesDailyGaps(
                        points: points,
                        from: window.from,
                        to: window.to,
                      );
                      return BsSalesLineChart(
                        key: ValueKey(chartRange),
                        points: filled,
                        period: _weeklyChart
                            ? SalesChartPeriod.weekly
                            : SalesChartPeriod.monthly,
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
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
                    l10n.recentActivity,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  _RecentActivityList(
                    bills: todaysBills,
                    lowStockAlerts: lowStockAlerts,
                  ),
                ],
              ),
            ),
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
                    l10n.todaysTransactions,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  todaysBills.when(
                    data: (bills) => _TransactionsList(bills: bills),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, _) => Text(l10n.loadingFailed),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SalesSummaryScreen()),
            ),
            child: Text(l10n.salesSummary),
          ),
        ],
      ),
    );
  }
}

class _RecentActivityList extends StatelessWidget {
  const _RecentActivityList({
    required this.bills,
    required this.lowStockAlerts,
  });

  final AsyncValue<List<Bill>> bills;
  final AsyncValue<List<Product>> lowStockAlerts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = <Widget>[];

    bills.whenData((list) {
      for (final bill in list.take(3)) {
        items.add(
          _ActivityRow(
            icon: Icons.shopping_cart_outlined,
            color: BsColors.primary,
            text: l10n.newBillCreated(bill.billNo),
          ),
        );
      }
    });

    lowStockAlerts.whenData((list) {
      for (final p in list) {
        items.add(
          _ActivityRow(
            icon: Icons.warning_amber_outlined,
            color: BsColors.danger,
            text: l10n.lowStockAlert(p.name),
          ),
        );
      }
    });

    if (items.isEmpty) {
      return Text(
        l10n.noSalesInPeriod,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: BsColors.outline),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < items.length.clamp(0, 5); i++) ...[
          if (i > 0) const SizedBox(height: 10),
          items[i],
        ],
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(BsRadii.md),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}

class _TransactionsList extends StatelessWidget {
  const _TransactionsList({required this.bills});

  final List<Bill> bills;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final timeFmt = DateFormat.jm();

    if (bills.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          l10n.noSalesInPeriod,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: BsColors.outline),
        ),
      );
    }

    return Column(
      children: [
        for (final bill in bills.take(8))
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(bill.customerShopName ?? l10n.walkInCustomer),
            subtitle: Text(
              bill.createdAt != null
                  ? timeFmt.format(bill.createdAt!.toLocal())
                  : bill.billNo,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatNpr(Paisa(bill.grandTotal), showPaisa: false),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                BillStatusChip(bill.status),
              ],
            ),
          ),
      ],
    );
  }
}
