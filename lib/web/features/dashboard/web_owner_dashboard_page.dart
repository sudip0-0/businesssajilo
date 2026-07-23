import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/export/export_actions.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/ui/bill_status_chip.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/report_range.dart';
import '../../../domain/enums.dart';
import '../../../domain/models/bill.dart';
import '../../../domain/models/customer.dart';
import '../../../domain/models/product.dart';
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
          icon: Icon(PhosphorIconsRegular.receipt, size: 18),
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
                              child: _RecentActivityList(
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
                          icon: Icon(PhosphorIconsRegular.export, size: 16),
                          label: Text(l10n.export),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    todaysBills.when(
                      data: (bills) => _TransactionsTable(bills: bills),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (_, _) => Text(l10n.loadingFailed),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.center,
                      child: TextButton.icon(
                        onPressed: () => context.go('/owner/billing'),
                        icon: Icon(PhosphorIconsRegular.arrowRight, size: 16),
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

class _RecentActivityList extends StatelessWidget {
  const _RecentActivityList({
    required this.bills,
    required this.lowStockAlerts,
    required this.recentCustomers,
  });

  final AsyncValue<List<Bill>> bills;
  final AsyncValue<List<Product>> lowStockAlerts;
  final AsyncValue<List<Customer>> recentCustomers;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = <_ActivityItem>[];

    bills.whenData((list) {
      for (final bill in list.take(3)) {
        items.add(
          _ActivityItem(
            icon: PhosphorIconsRegular.receipt,
            color: WebPalette.navy,
            text: l10n.newBillCreated(bill.billNo),
            onTap: () => context.go('/owner/billing/${bill.id}'),
          ),
        );
      }
    });

    lowStockAlerts.whenData((list) {
      for (final p in list) {
        items.add(
          _ActivityItem(
            icon: PhosphorIconsRegular.warning,
            color: WebPalette.danger,
            text: l10n.lowStockAlert(p.name),
            onTap: () => context.go('/owner/inventory/${p.id}'),
          ),
        );
      }
    });

    recentCustomers.whenData((list) {
      for (final c in list) {
        items.add(
          _ActivityItem(
            icon: PhosphorIconsRegular.user,
            color: WebPalette.success,
            text: l10n.newCustomerAdded(c.shopName),
            onTap: () => context.go('/owner/customers/${c.id}'),
          ),
        );
      }
    });

    if (items.isEmpty) {
      return Center(
        child: Text(
          l10n.noRecentActivity,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: WebPalette.inkSoft),
        ),
      );
    }

    return ListView.separated(
      itemCount: items.length.clamp(0, 5),
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) => items[index],
    );
  }
}

class _ActivityItem extends StatelessWidget {
  const _ActivityItem({
    required this.icon,
    required this.color,
    required this.text,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionsTable extends StatelessWidget {
  const _TransactionsTable({required this.bills});

  final List<Bill> bills;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final timeFmt = DateFormat.jm();

    if (bills.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            l10n.noSalesInPeriod,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: WebPalette.inkSoft),
          ),
        ),
      );
    }

    final headerStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: WebPalette.inkSoft,
      fontWeight: FontWeight.w600,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        const minTableWidth = 720.0;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth < minTableWidth
                  ? minTableWidth
                  : constraints.maxWidth,
            ),
            child: Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: const {
                0: FixedColumnWidth(72),
                1: FlexColumnWidth(2.4),
                2: FlexColumnWidth(1.1),
                3: FlexColumnWidth(1.1),
                4: FlexColumnWidth(1.3),
                5: FlexColumnWidth(1.2),
              },
              children: [
                TableRow(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: WebPalette.hairline),
                    ),
                  ),
                  children: [
                    _headerCell(l10n.sn, headerStyle),
                    _headerCell(l10n.customerName, headerStyle),
                    _headerCell(l10n.time, headerStyle),
                    _headerCell(l10n.payment, headerStyle),
                    _headerCell(l10n.amountNpr, headerStyle),
                    _headerCell(l10n.status, headerStyle),
                  ],
                ),
                for (final bill in bills)
                  TableRow(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: WebPalette.hairline),
                      ),
                    ),
                    children: [
                      _dataCell(
                        onTap: () => context.go('/owner/billing/${bill.id}'),
                        child: Text(
                          '#${bill.billNo.split('-').last}',
                          style: WebTypography.mono(
                            fontSize: 12,
                            color: WebPalette.inkSoft,
                          ),
                        ),
                      ),
                      _dataCell(
                        onTap: () => context.go('/owner/billing/${bill.id}'),
                        child: Text(
                          bill.customerShopName ?? l10n.walkInCustomer,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _dataCell(
                        onTap: () => context.go('/owner/billing/${bill.id}'),
                        child: Text(
                          bill.createdAt != null
                              ? timeFmt.format(bill.createdAt!.toLocal())
                              : '—',
                        ),
                      ),
                      _dataCell(
                        onTap: () => context.go('/owner/billing/${bill.id}'),
                        child: Text(_paymentLabel(bill.status, l10n)),
                      ),
                      _dataCell(
                        onTap: () => context.go('/owner/billing/${bill.id}'),
                        child: Text(
                          formatNpr(Paisa(bill.grandTotal), showPaisa: false),
                          style: WebTypography.mono(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: WebPalette.ink,
                          ),
                        ),
                      ),
                      _dataCell(
                        onTap: () => context.go('/owner/billing/${bill.id}'),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: BillStatusChip(bill.status),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _headerCell(String label, TextStyle? style) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      child: Text(label, style: style),
    );
  }

  Widget _dataCell({required Widget child, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: child,
        ),
      ),
    );
  }

  String _paymentLabel(BillStatus status, AppLocalizations l10n) {
    return switch (status) {
      BillStatus.paid => l10n.paymentMethodCash,
      BillStatus.partial => l10n.partial,
      BillStatus.due => l10n.due,
    };
  }
}
