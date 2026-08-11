import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/ui/bill_status_chip.dart';
import '../../../core/ui/bs_sales_line_chart.dart';
import '../../../core/utils/bill_customer_label.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/report_range.dart';
import '../../../domain/models/bill.dart';
import '../../../domain/models/sales_period_point.dart';
import '../../../domain/models/top_customer_row.dart';
import '../../../domain/models/top_product_row.dart';
import '../../../features/reports/providers.dart';
import '../../../features/reports/report_export_actions.dart';
import '../../../features/reports/report_period.dart';
import '../../layout/web_bento_grid.dart';
import '../../theme/web_typography.dart';
import '../../ui/web_data_table.dart';
import '../../ui/web_empty_state.dart';
import '../../ui/web_stat_tile.dart';
import '../web_page_scaffold.dart';
import 'widgets/ranked_meter_list.dart';
import 'widgets/report_filter_bar.dart';
import 'widgets/report_period_picker.dart';

class WebSalesReportPage extends ConsumerStatefulWidget {
  const WebSalesReportPage({super.key, this.initialPeriod});

  final String? initialPeriod;

  @override
  ConsumerState<WebSalesReportPage> createState() => _WebSalesReportPageState();
}

class _WebSalesReportPageState extends ConsumerState<WebSalesReportPage> {
  late ReportPeriod _period;
  String _search = '';
  Timer? _debounce;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _period = ReportPeriod.fromQuery(widget.initialPeriod);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _search = value.trim());
    });
  }

  int _sumSales(List<SalesPeriodPoint> points) =>
      points.fold<int>(0, (s, p) => s + p.totalSales);

  int _sumBills(List<SalesPeriodPoint> points) =>
      points.fold<int>(0, (s, p) => s + p.billCount);

  WebTrendDirection? _trendDir(int current, int previous) {
    if (previous == 0 && current == 0) return WebTrendDirection.neutral;
    if (current > previous) return WebTrendDirection.up;
    if (current < previous) return WebTrendDirection.down;
    return WebTrendDirection.neutral;
  }

  String? _trendLabel(int current, int previous, AppLocalizations l10n) {
    if (previous == 0) {
      return current == 0 ? null : l10n.vsPreviousPeriod;
    }
    final pct = ((current - previous).abs() / previous * 100).round();
    return '$pct% ${l10n.vsPreviousPeriod}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final salesAsync = ref.watch(salesDailyRangeProvider(_period));
    final prevAsync = ref.watch(
      salesDailyRangeProvider(_period.previousEqualLength),
    );
    final productsAsync = ref.watch(topProductsRangeProvider(_period));
    final customersAsync = ref.watch(topCustomersRangeProvider(_period));
    final billsAsync = ref.watch(
      billsInRangeProvider(
        BillsRangeQuery(period: _period, query: _search),
      ),
    );

    return WebPageScaffold(
      title: l10n.salesSummary,
      breadcrumbs: [l10n.reports, l10n.salesSummary],
      actions: [
        IconButton(
          tooltip: l10n.exportCsv,
          onPressed: () => _exportCsv(context),
          icon: const Icon(Icons.download_outlined),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ReportFilterBar(
            leading: ReportPeriodPicker(
              value: _period,
              onChanged: (p) => setState(() => _period = p),
            ),
            searchHint: l10n.searchBillsHint,
            searchController: _searchController,
            onSearchChanged: _onSearchChanged,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: salesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => WebEmptyState(
                icon: PhosphorIconsRegular.warningCircle,
                message: l10n.loadingFailed,
                actionLabel: l10n.tryAgain,
                onAction: () {
                  ref.invalidate(salesDailyRangeProvider(_period));
                  ref.invalidate(topProductsRangeProvider(_period));
                  ref.invalidate(topCustomersRangeProvider(_period));
                  ref.invalidate(
                    billsInRangeProvider(
                      BillsRangeQuery(period: _period, query: _search),
                    ),
                  );
                },
              ),
              data: (points) {
                final filled = fillSalesDailyGaps(
                  points: points,
                  from: _period.from,
                  to: _period.to,
                );
                final netSales = _sumSales(filled);
                final billCount = _sumBills(filled);
                final avgBill = billCount == 0 ? 0 : netSales ~/ billCount;
                final prevPoints = prevAsync.value ?? const [];
                final prevSales = _sumSales(prevPoints);
                final prevBills = _sumBills(prevPoints);
                final prevAvg = prevBills == 0 ? 0 : prevSales ~/ prevBills;
                final chartPeriod = filled.length <= 8
                    ? SalesChartPeriod.weekly
                    : SalesChartPeriod.monthly;

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(salesDailyRangeProvider(_period));
                    ref.invalidate(topProductsRangeProvider(_period));
                    ref.invalidate(topCustomersRangeProvider(_period));
                    ref.invalidate(
                      billsInRangeProvider(
                        BillsRangeQuery(period: _period, query: _search),
                      ),
                    );
                    await ref.read(salesDailyRangeProvider(_period).future);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        WebBentoGrid(
                          columns: 3,
                          children: [
                            WebStatTile(
                              label: l10n.netSales,
                              value: formatNpr(
                                Paisa(netSales),
                                showPaisa: false,
                              ),
                              icon: PhosphorIconsRegular.chartLineUp,
                              trend: _trendDir(netSales, prevSales),
                              trendLabel: _trendLabel(
                                netSales,
                                prevSales,
                                l10n,
                              ),
                            ),
                            WebStatTile(
                              label: l10n.billCount,
                              value: '$billCount',
                              icon: PhosphorIconsRegular.receipt,
                              trend: _trendDir(billCount, prevBills),
                              trendLabel: _trendLabel(
                                billCount,
                                prevBills,
                                l10n,
                              ),
                            ),
                            WebStatTile(
                              label: l10n.avgBillValue,
                              value: formatNpr(
                                Paisa(avgBill),
                                showPaisa: false,
                              ),
                              icon: PhosphorIconsRegular.currencyCircleDollar,
                              trend: _trendDir(avgBill, prevAvg),
                              trendLabel: _trendLabel(avgBill, prevAvg, l10n),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        WebBentoTile(
                          minHeight: 280,
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.salesSummary,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 16),
                              BsSalesLineChart(
                                points: filled,
                                height: 220,
                                period: chartPeriod,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final wide = constraints.maxWidth >= 900;
                            final products = _TopProductsCard(
                              async: productsAsync,
                              l10n: l10n,
                            );
                            final customers = _TopCustomersCard(
                              async: customersAsync,
                              l10n: l10n,
                            );
                            if (wide) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: products),
                                  const SizedBox(width: 16),
                                  Expanded(child: customers),
                                ],
                              );
                            }
                            return Column(
                              children: [
                                products,
                                const SizedBox(height: 16),
                                customers,
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        Text(
                          l10n.billsInPeriod,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 420,
                          child: billsAsync.when(
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (_, _) => WebEmptyState(
                              icon: PhosphorIconsRegular.warningCircle,
                              message: l10n.loadingFailed,
                              actionLabel: l10n.tryAgain,
                              onAction: () => ref.invalidate(
                                billsInRangeProvider(
                                  BillsRangeQuery(
                                    period: _period,
                                    query: _search,
                                  ),
                                ),
                              ),
                            ),
                            data: (bills) => bills.isEmpty
                                ? WebEmptyState(
                                    icon: PhosphorIconsRegular.receipt,
                                    message: _search.isEmpty
                                        ? l10n.noSalesInPeriod
                                        : l10n.noMatchingResults,
                                  )
                                : _BillsTable(bills: bills),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCsv(BuildContext context) async {
    // Reuse existing ReportRange export for presets closest to selection;
    // custom periods export via the same sales data currently loaded.
    final l10n = AppLocalizations.of(context);
    final daily = await ref.read(salesDailyRangeProvider(_period).future);
    final topProducts = await ref.read(
      topProductsRangeProvider(_period).future,
    );
    final topCustomers = await ref.read(
      topCustomersRangeProvider(_period).future,
    );
    if (!context.mounted) return;
    await exportSalesReportCsvFromData(
      ref,
      context,
      daily: daily,
      topProducts: topProducts,
      topCustomers: topCustomers,
      subject: l10n.salesSummary,
    );
  }
}

class _TopProductsCard extends StatelessWidget {
  const _TopProductsCard({required this.async, required this.l10n});

  final AsyncValue<List<TopProductRow>> async;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return WebBentoTile(
      minHeight: 280,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.topProducts, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 14),
          async.when(
            loading: () => const SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => Text(l10n.loadingFailed),
            data: (rows) => RankedMeterList(
              emptyMessage: l10n.noSalesInPeriod,
              emptyIcon: PhosphorIconsRegular.package,
              items: [
                for (final r in rows)
                  RankedMeterItem(
                    id: r.productId,
                    label: r.nameSnapshot,
                    subtitle: '${r.qtySold} ${l10n.qty.toLowerCase()}',
                    valueLabel: formatNpr(Paisa(r.revenue), showPaisa: false),
                    metric: r.revenue,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopCustomersCard extends StatelessWidget {
  const _TopCustomersCard({required this.async, required this.l10n});

  final AsyncValue<List<TopCustomerRow>> async;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return WebBentoTile(
      minHeight: 280,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.topCustomers,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 14),
          async.when(
            loading: () => const SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => Text(l10n.loadingFailed),
            data: (rows) => RankedMeterList(
              emptyMessage: l10n.noSalesInPeriod,
              emptyIcon: PhosphorIconsRegular.users,
              onTap: (item) => context.go('/owner/customers/${item.id}'),
              items: [
                for (final r in rows)
                  RankedMeterItem(
                    id: r.customerId,
                    label: r.shopName,
                    subtitle: '${r.billCount} ${l10n.bills.toLowerCase()}',
                    valueLabel: formatNpr(Paisa(r.revenue), showPaisa: false),
                    metric: r.revenue,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BillsTable extends StatelessWidget {
  const _BillsTable({required this.bills});

  final List<Bill> bills;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateFmt = DateFormat.MMMd().add_jm();

    return WebDataTable<Bill>(
      columns: [
        DataColumn(label: Text(l10n.bills)),
        DataColumn(label: Text(l10n.time)),
        DataColumn(label: Text(l10n.customers)),
        DataColumn(label: Text(l10n.status)),
        DataColumn(label: Text(l10n.amountNpr), numeric: true),
      ],
      items: bills,
      idFor: (b) => b.id,
      onRowTap: (b) => context.go('/owner/billing/${b.id}'),
      rowBuilder: (b, _) {
        final created = b.createdAt;
        final npt = created == null
            ? '—'
            : dateFmt.format(created.toUtc().add(nptOffset));
        return DataRow(
          cells: [
            DataCell(
              Text(
                b.billNo,
                style: WebTypography.mono(fontSize: 12.5),
              ),
            ),
            DataCell(Text(npt)),
            DataCell(
              Text(billCustomerLabel(b, walkInLabel: l10n.walkIn)),
            ),
            DataCell(BillStatusChip(b.status)),
            DataCell(
              Text(
                formatNpr(Paisa(b.grandTotal), showPaisa: false),
                style: WebTypography.mono(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
