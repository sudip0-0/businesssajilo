import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/export/export_actions.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/layout/adaptive_scaffold.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/money_text.dart';
import '../../core/utils/money.dart';
import '../../domain/enums.dart';
import '../../core/ui/bs_sales_line_chart.dart';
import 'providers.dart';

class SalesSummaryScreen extends ConsumerStatefulWidget {
  const SalesSummaryScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<SalesSummaryScreen> createState() => _SalesSummaryScreenState();
}

class _SalesSummaryScreenState extends ConsumerState<SalesSummaryScreen> {
  ReportRange _range = ReportRange.week;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final salesAsync = ref.watch(salesDailyProvider(_range));
    final productsAsync = ref.watch(topProductsProvider(_range));
    final customersAsync = ref.watch(topCustomersProvider(_range));

    final body = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: Text(l10n.periodToday),
              selected: _range == ReportRange.today,
              onSelected: (_) => setState(() => _range = ReportRange.today),
            ),
            ChoiceChip(
              label: Text(l10n.periodWeek),
              selected: _range == ReportRange.week,
              onSelected: (_) => setState(() => _range = ReportRange.week),
            ),
            ChoiceChip(
              label: Text(l10n.periodMonth),
              selected: _range == ReportRange.month,
              onSelected: (_) => setState(() => _range = ReportRange.month),
            ),
            IconButton(
              tooltip: l10n.exportCsv,
              onPressed: () => exportSalesReportCsv(ref, context, _range),
              icon: const Icon(Icons.download_outlined),
            ),
          ],
        ),
        const SizedBox(height: 16),
        salesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text(l10n.loadingFailed),
          data: (points) {
            final total = points.fold<int>(0, (sum, p) => sum + p.totalSales);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.totalSales,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                MoneyText(
                  Paisa(total),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                if (points.isEmpty)
                  EmptyState(
                    icon: Icons.trending_up,
                    message: l10n.noSalesInPeriod,
                  )
                else
                  BsSalesLineChart(points: points),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        Text(l10n.topProducts, style: Theme.of(context).textTheme.titleMedium),
        productsAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text(l10n.loadingFailed),
          data: (rows) => _RankedList(
            wide: isWideLayout(context),
            nameLabel: l10n.name,
            revenueLabel: l10n.revenue,
            items: rows
                .map(
                  (r) => (
                    r.nameSnapshot,
                    formatNpr(Paisa(r.revenue), showPaisa: false),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 16),
        Text(l10n.topCustomers, style: Theme.of(context).textTheme.titleMedium),
        customersAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text(l10n.loadingFailed),
          data: (rows) => _RankedList(
            wide: isWideLayout(context),
            nameLabel: l10n.name,
            revenueLabel: l10n.revenue,
            items: rows
                .map(
                  (r) => (
                    r.shopName,
                    formatNpr(Paisa(r.revenue), showPaisa: false),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );

    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.salesSummary)),
      body: body,
    );
  }
}

class _RankedList extends StatelessWidget {
  const _RankedList({
    required this.wide,
    required this.items,
    required this.nameLabel,
    required this.revenueLabel,
  });

  final bool wide;
  final List<(String, String)> items;
  final String nameLabel;
  final String revenueLabel;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('—'),
      );
    }

    if (wide) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            const DataColumn(label: Text('#')),
            DataColumn(label: Text(nameLabel)),
            DataColumn(label: Text(revenueLabel), numeric: true),
          ],
          rows: [
            for (var i = 0; i < items.length; i++)
              DataRow(
                cells: [
                  DataCell(Text('${i + 1}')),
                  DataCell(Text(items[i].$1)),
                  DataCell(Text(items[i].$2)),
                ],
              ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          ListTile(
            dense: true,
            title: Text(items[i].$1),
            trailing: Text(items[i].$2),
            leading: CircleAvatar(radius: 12, child: Text('${i + 1}')),
          ),
      ],
    );
  }
}
