import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/layout/adaptive_scaffold.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/bill_status_chip.dart';
import '../../core/ui/bs_sales_line_chart.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/money_text.dart';
import '../../core/utils/bill_customer_label.dart';
import '../../core/utils/money.dart';
import '../../domain/models/top_customer_row.dart';
import '../../domain/models/top_product_row.dart';
import '../billing/bill_detail_screen.dart';
import '../customers/customer_detail_screen.dart';
import 'providers.dart';
import 'report_export_actions.dart';
import 'report_period.dart';
import 'report_period_picker.dart';

enum _SalesTab { overview, products, customers, bills }

class SalesSummaryScreen extends ConsumerStatefulWidget {
  const SalesSummaryScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<SalesSummaryScreen> createState() => _SalesSummaryScreenState();
}

class _SalesSummaryScreenState extends ConsumerState<SalesSummaryScreen> {
  ReportPeriod _period = ReportPeriod.preset(ReportPeriodPreset.last7Days);
  _SalesTab _currentTab = _SalesTab.overview;
  String _billSearch = '';
  final _billSearchController = TextEditingController();

  @override
  void dispose() {
    _billSearchController.dispose();
    super.dispose();
  }

  Future<void> _exportCsv(BuildContext context) async {
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final salesAsync = ref.watch(salesDailyRangeProvider(_period));
    final productsAsync = ref.watch(topProductsRangeProvider(_period));
    final customersAsync = ref.watch(topCustomersRangeProvider(_period));
    final billsAsync = ref.watch(
      billsInRangeProvider(
        BillsRangeQuery(period: _period, query: _billSearch),
      ),
    );
    final isWide = isWideLayout(context);

    final body = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ReportPeriodPicker(
                value: _period,
                onChanged: (p) => setState(() => _period = p),
              ),
            ),
            IconButton(
              tooltip: l10n.exportCsv,
              onPressed: () => _exportCsv(context),
              icon: const Icon(Icons.download_outlined),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Sub-tabs segment
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChoiceChip(
                label: Text(l10n.salesSummary),
                selected: _currentTab == _SalesTab.overview,
                onSelected: (_) =>
                    setState(() => _currentTab = _SalesTab.overview),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text(l10n.topProducts),
                selected: _currentTab == _SalesTab.products,
                onSelected: (_) =>
                    setState(() => _currentTab = _SalesTab.products),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text(l10n.topCustomers),
                selected: _currentTab == _SalesTab.customers,
                onSelected: (_) =>
                    setState(() => _currentTab = _SalesTab.customers),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text(l10n.bills),
                selected: _currentTab == _SalesTab.bills,
                onSelected: (_) => setState(() => _currentTab = _SalesTab.bills),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_currentTab == _SalesTab.overview) ...[
          salesAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => ErrorState(
              message: l10n.loadingFailed,
              onRetry: () => ref.invalidate(salesDailyRangeProvider(_period)),
            ),
            data: (points) {
              final totalSales = points.fold<int>(
                0,
                (sum, p) => sum + p.totalSales,
              );
              final totalBills = points.fold<int>(
                0,
                (sum, p) => sum + p.billCount,
              );
              final aov = totalBills > 0 ? (totalSales ~/ totalBills) : 0;
              final maxDaily = points.fold<int>(
                0,
                (max, p) => p.totalSales > max ? p.totalSales : max,
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // KPI Summary Bento
                  GridView.count(
                    crossAxisCount: isWide ? 4 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: isWide ? 2.0 : 1.35,
                    children: [
                      _KpiCard(
                        label: l10n.totalSales,
                        value: formatNpr(Paisa(totalSales), showPaisa: false),
                        icon: Icons.trending_up,
                        color: BsColors.primary,
                      ),
                      _KpiCard(
                        label: l10n.totalInvoices,
                        value: '$totalBills',
                        icon: Icons.receipt_long_outlined,
                        color: Colors.indigo,
                      ),
                      _KpiCard(
                        label: l10n.averageOrderValue,
                        value: formatNpr(Paisa(aov), showPaisa: false),
                        icon: Icons.analytics_outlined,
                        color: Colors.teal,
                      ),
                      _KpiCard(
                        label: l10n.bestMonth,
                        value: formatNpr(Paisa(maxDaily), showPaisa: false),
                        icon: Icons.star_border_rounded,
                        color: Colors.amber.shade800,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.salesPerformance,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              MoneyText(
                                Paisa(totalSales),
                                showPaisa: false,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: BsColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (points.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: EmptyState(
                                icon: Icons.trending_up,
                                message: l10n.noSalesInPeriod,
                              ),
                            )
                          else
                            BsSalesLineChart(points: points),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          // Top Products Quick Preview
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.topProducts,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () =>
                    setState(() => _currentTab = _SalesTab.products),
                child: Text(l10n.viewReport),
              ),
            ],
          ),
          productsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => ErrorState(
              message: l10n.loadingFailed,
              onRetry: () => ref.invalidate(topProductsRangeProvider(_period)),
            ),
            data: (rows) => _TopProductsList(
              rows: rows.take(3).toList(),
              onViewAll: () =>
                  setState(() => _currentTab = _SalesTab.products),
            ),
          ),
          const SizedBox(height: 16),
          // Top Customers Quick Preview
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.topCustomers,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () =>
                    setState(() => _currentTab = _SalesTab.customers),
                child: Text(l10n.viewReport),
              ),
            ],
          ),
          customersAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => ErrorState(
              message: l10n.loadingFailed,
              onRetry: () => ref.invalidate(topCustomersRangeProvider(_period)),
            ),
            data: (rows) => _TopCustomersList(
              rows: rows.take(3).toList(),
              onViewAll: () =>
                  setState(() => _currentTab = _SalesTab.customers),
            ),
          ),
        ] else if (_currentTab == _SalesTab.products) ...[
          Text(
            l10n.topProducts,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          productsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => ErrorState(
              message: l10n.loadingFailed,
              onRetry: () => ref.invalidate(topProductsRangeProvider(_period)),
            ),
            data: (rows) => _TopProductsList(rows: rows),
          ),
        ] else if (_currentTab == _SalesTab.customers) ...[
          Text(
            l10n.topCustomers,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          customersAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => ErrorState(
              message: l10n.loadingFailed,
              onRetry: () => ref.invalidate(topCustomersRangeProvider(_period)),
            ),
            data: (rows) => _TopCustomersList(rows: rows),
          ),
        ] else if (_currentTab == _SalesTab.bills) ...[
          TextField(
            controller: _billSearchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, size: 20),
              hintText: l10n.searchBillsHint,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              suffixIcon: _billSearch.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _billSearchController.clear();
                        setState(() => _billSearch = '');
                      },
                    )
                  : null,
            ),
            onChanged: (val) => setState(() => _billSearch = val.trim()),
          ),
          const SizedBox(height: 12),
          billsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => ErrorState(
              message: l10n.loadingFailed,
              onRetry: () => ref.invalidate(billsInRangeProvider),
            ),
            data: (bills) {
              if (bills.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: EmptyState(
                    icon: Icons.receipt_long_outlined,
                    message: l10n.noSalesInPeriod,
                  ),
                );
              }
              return Column(
                children: [
                  for (final b in bills) ...[
                    Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: Theme.of(
                            context,
                          ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        title: Row(
                          children: [
                            Text(
                              b.billNo,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            BillStatusChip(b.status),
                          ],
                        ),
                        subtitle: Text(
                          billCustomerLabel(b, walkInLabel: l10n.walkInCustomer),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            MoneyText(
                              Paisa(b.grandTotal),
                              showPaisa: false,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: BsColors.outline,
                              size: 18,
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BillDetailScreen(billId: b.id),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ],
    );

    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.salesSummary)),
      body: body,
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopProductsList extends StatelessWidget {
  const _TopProductsList({required this.rows, this.onViewAll});

  final List<TopProductRow> rows;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (rows.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              l10n.noSalesInPeriod,
              style: const TextStyle(color: BsColors.outline),
            ),
          ),
        ),
      );
    }

    final maxRevenue = rows.fold<int>(
      0,
      (max, r) => r.revenue > max ? r.revenue : max,
    );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: rows.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final p = rows[index];
          final ratio = maxRevenue > 0 ? (p.revenue / maxRevenue) : 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: index < 3
                            ? BsColors.primary.withValues(alpha: 0.15)
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: index < 3
                              ? BsColors.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        p.nameSnapshot,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatNpr(Paisa(p.revenue), showPaisa: false),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${p.qtySold} ${l10n.qtySold.toLowerCase()}',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: BsColors.outline),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: ratio.clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      index == 0
                          ? BsColors.primary
                          : BsColors.primary.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TopCustomersList extends StatelessWidget {
  const _TopCustomersList({required this.rows, this.onViewAll});

  final List<TopCustomerRow> rows;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (rows.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              l10n.noSalesInPeriod,
              style: const TextStyle(color: BsColors.outline),
            ),
          ),
        ),
      );
    }

    final maxRevenue = rows.fold<int>(
      0,
      (max, r) => r.revenue > max ? r.revenue : max,
    );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: rows.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final c = rows[index];
          final ratio = maxRevenue > 0 ? (c.revenue / maxRevenue) : 0.0;
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CustomerDetailScreen(customerId: c.customerId),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: index < 3
                              ? Colors.teal.withValues(alpha: 0.15)
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: index < 3
                                ? Colors.teal
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          c.shopName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatNpr(Paisa(c.revenue), showPaisa: false),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${c.billCount} ${l10n.bills.toLowerCase()}',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: BsColors.outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: ratio.clamp(0.0, 1.0),
                      minHeight: 4,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        index == 0
                            ? Colors.teal
                            : Colors.teal.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
