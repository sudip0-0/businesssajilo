import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/bill_status_chip.dart';
import '../../../core/utils/money.dart';
import '../../../domain/enums.dart';
import '../../../domain/models/bill.dart';
import '../../../domain/models/customer.dart';
import '../../../domain/models/product.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/billing/providers.dart';
import '../../../features/customers/providers.dart';
import '../../../features/inventory/providers.dart';
import '../../../features/orders/providers.dart' as orders;
import '../../../features/reports/providers.dart';
import '../web_page_scaffold.dart';
import '../../layout/web_bento_grid.dart';
import '../../ui/web_sales_line_chart.dart';
import '../../ui/web_search_field.dart';
import '../../ui/web_stat_tile.dart';
import '../../ui/web_success_button.dart';
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
    ref.invalidate(salesDailyProvider(ReportRange.month));
    ref.invalidate(todaysSalesProvider);
    ref.invalidate(yesterdaysSalesProvider);
    ref.invalidate(salesTrendProvider);
    ref.invalidate(totalDuesProvider);
    ref.invalidate(lowStockCountProvider);
    ref.invalidate(orders.pendingOrdersCountProvider);
    ref.invalidate(todaysBillsProvider);
    ref.invalidate(billListProvider);
    ref.invalidate(customerListProvider);
    ref.invalidate(productListProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authProvider).value;
    final name = auth?.member?.displayName ?? '';
    final todaysSales = ref.watch(todaysSalesProvider);
    final salesTrend = ref.watch(salesTrendProvider);
    final totalDues = ref.watch(totalDuesProvider);
    final lowStock = ref.watch(lowStockCountProvider);
    final pendingOrders = ref.watch(orders.pendingOrdersCountProvider);
    final chartRange = _weeklyChart ? ReportRange.last7Days : ReportRange.month;
    final chartData = ref.watch(salesDailyProvider(chartRange));
    final todaysBills = ref.watch(todaysBillsProvider);
    final products = ref.watch(productListProvider);
    final customers = ref.watch(customerListProvider);

    return WebPageScaffold(
      title: l10n.namasteGreeting(name),
      subtitle: l10n.dashboardTodaySummary,
      fillHeight: false,
      actions: [
        OutlinedButton(
          key: IntegrationKeys.dashboardAddProduct,
          onPressed: () => context.push('/owner/inventory/new'),
          child: Text(l10n.addProduct),
        ),
        const SizedBox(width: 8),
        WebSuccessButton(
          key: IntegrationKeys.dashboardNewBill,
          onPressed: () => context.push('/owner/billing/new'),
          icon: Icon(PhosphorIconsRegular.receipt, size: 18),
          label: l10n.newBill,
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
                    value: todaysSales.when(
                      data: (d) => formatNpr(Paisa(d), showPaisa: false),
                      loading: () => '…',
                      error: (_, _) => '—',
                    ),
                    icon: PhosphorIconsRegular.currencyDollar,
                    trend: salesTrend.when(
                      data: (pct) {
                        if (pct == null) return null;
                        return pct >= 0
                            ? WebTrendDirection.up
                            : WebTrendDirection.down;
                      },
                      loading: () => null,
                      error: (_, _) => null,
                    ),
                    trendLabel: salesTrend.when(
                      data: (pct) =>
                          pct == null ? null : '${pct.abs().toStringAsFixed(0)}%',
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
                    subtitle: totalDues.when(
                      data: (d) => d > 0 ? l10n.needsAttention : null,
                      loading: () => null,
                      error: (_, _) => null,
                    ),
                    onTap: () => context.go('/owner/reports/dues'),
                  ),
                  WebStatTile(
                    label: l10n.lowStock,
                    value: lowStock.when(
                      data: (c) => '$c ${l10n.products.toLowerCase()}',
                      loading: () => '…',
                      error: (_, _) => '—',
                    ),
                    icon: PhosphorIconsRegular.package,
                    subtitle: lowStock.when(
                      data: (c) => c > 0 ? l10n.reorderSoon : null,
                      loading: () => null,
                      error: (_, _) => null,
                    ),
                    onTap: () => context.go('/owner/reports/stock'),
                  ),
                  WebStatTile(
                    label: l10n.pendingOrders,
                    value: pendingOrders.when(
                      data: (c) => '$c ${l10n.orders.toLowerCase()}',
                      loading: () => '…',
                      error: (_, _) => '—',
                    ),
                    icon: PhosphorIconsRegular.shoppingCart,
                    trendLabel: pendingOrders.when(
                      data: (c) => c > 0 ? '$c NEW' : null,
                      loading: () => null,
                      error: (_, _) => null,
                    ),
                    trend: pendingOrders.when(
                      data: (c) => c > 0 ? WebTrendDirection.neutral : null,
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
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.salesPerformance,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  Text(
                                    l10n.salesPerformanceSubtitle,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: BsColors.outline),
                                  ),
                                ],
                              ),
                            ),
                            SegmentedButton<bool>(
                              showSelectedIcon: false,
                              segments: [
                                ButtonSegment(
                                  value: true,
                                  label: Text(l10n.weekly),
                                ),
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
                        const SizedBox(height: 20),
                        chartData.when(
                          data: (data) => WebSalesLineChart(points: data),
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
                              onChanged: (_) {},
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
                                products: products,
                                customers: customers,
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
                          onPressed: () {},
                          icon: Icon(PhosphorIconsRegular.funnel, size: 16),
                          label: Text(l10n.filter),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () {},
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
              const SizedBox(height: 24),
              Center(
                child: Text(
                  '© ${DateTime.now().year} ${l10n.appTitle.toUpperCase()} • ${l10n.madeForNepal.toUpperCase()}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: BsColors.outline,
                        letterSpacing: 0.5,
                      ),
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
    required this.products,
    required this.customers,
  });

  final AsyncValue<List<Bill>> bills;
  final AsyncValue<List<Product>> products;
  final AsyncValue<List<Customer>> customers;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = <_ActivityItem>[];

    bills.whenData((list) {
      for (final bill in list.take(3)) {
        items.add(
          _ActivityItem(
            icon: PhosphorIconsRegular.shoppingCart,
            color: BsColors.primary,
            text: l10n.newBillCreated(bill.billNo),
          ),
        );
      }
    });

    products.whenData((list) {
      for (final p in list
          .where((p) =>
              p.lowStockThreshold > 0 && p.stockCached <= p.lowStockThreshold)
          .take(2)) {
        items.add(
          _ActivityItem(
            icon: PhosphorIconsRegular.warning,
            color: BsColors.danger,
            text: l10n.lowStockAlert(p.name),
          ),
        );
      }
    });

    customers.whenData((list) {
      final recent = list.toList()
        ..sort((a, b) =>
            (b.createdAt ?? DateTime(1970)).compareTo(a.createdAt ?? DateTime(1970)));
      for (final c in recent.take(2)) {
        items.add(
          _ActivityItem(
            icon: PhosphorIconsRegular.user,
            color: BsColors.secondary,
            text: l10n.newCustomerAdded(c.shopName),
          ),
        );
      }
    });

    if (items.isEmpty) {
      return Center(
        child: Text(
          l10n.noSalesInPeriod,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: BsColors.outline,
              ),
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
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: BsColors.outline,
                ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 40,
        dataRowMinHeight: 44,
        dataRowMaxHeight: 52,
        columnSpacing: 24,
        columns: [
          DataColumn(label: Text(l10n.sn)),
          DataColumn(label: Text(l10n.customerName)),
          DataColumn(label: Text(l10n.time)),
          DataColumn(label: Text(l10n.payment)),
          DataColumn(label: Text(l10n.amountNpr)),
          DataColumn(label: Text(l10n.status)),
        ],
        rows: [
          for (var i = 0; i < bills.length; i++)
            DataRow(
              cells: [
                DataCell(Text('#${bills[i].billNo.split('-').last}')),
                DataCell(Text(
                  bills[i].customerShopName ?? l10n.walkInCustomer,
                )),
                DataCell(Text(
                  bills[i].createdAt != null
                      ? timeFmt.format(bills[i].createdAt!.toLocal())
                      : '—',
                )),
                DataCell(Text(_paymentLabel(bills[i].status, l10n))),
                DataCell(Text(
                  formatNpr(Paisa(bills[i].grandTotal), showPaisa: false),
                )),
                DataCell(BillStatusChip(bills[i].status)),
              ],
            ),
        ],
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
