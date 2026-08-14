import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'report_export_actions.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/layout/adaptive_scaffold.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/money_text.dart';
import '../../core/utils/money.dart';
import '../../core/ui/bs_sales_line_chart.dart';
import 'providers.dart';
import 'report_period.dart';
import 'report_period_picker.dart';

class SalesSummaryScreen extends ConsumerStatefulWidget {
  const SalesSummaryScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<SalesSummaryScreen> createState() => _SalesSummaryScreenState();
}

class _SalesSummaryScreenState extends ConsumerState<SalesSummaryScreen> {
  ReportPeriod _period = ReportPeriod.preset(ReportPeriodPreset.last7Days);

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
        const SizedBox(height: 16),
        salesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorState(
            message: l10n.loadingFailed,
            onRetry: () => ref.invalidate(salesDailyRangeProvider(_period)),
          ),
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
          error: (e, _) => ErrorState(
            message: l10n.loadingFailed,
            onRetry: () => ref.invalidate(topProductsRangeProvider(_period)),
          ),
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
          error: (e, _) => ErrorState(
            message: l10n.loadingFailed,
            onRetry: () => ref.invalidate(topCustomersRangeProvider(_period)),
          ),
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
