import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/export/export_share_service.dart';
import '../../core/export/report_csv_export.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/layout/adaptive_scaffold.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/money_text.dart';
import '../../core/utils/bs_calendar.dart';
import '../../core/utils/money.dart';
import 'providers.dart';
import 'report_period.dart';
import 'report_period_picker.dart';

/// Sales grouped by Bikram Sambat month (fiscal year = Shrawan–Ashadh).
class FiscalSummaryScreen extends ConsumerStatefulWidget {
  const FiscalSummaryScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<FiscalSummaryScreen> createState() =>
      _FiscalSummaryScreenState();
}

class _FiscalSummaryScreenState extends ConsumerState<FiscalSummaryScreen> {
  ReportPeriod _period = ReportPeriod.preset(ReportPeriodPreset.bsFiscalYear);

  Future<void> _exportCsv() async {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final daily = await ref.read(salesDailyRangeProvider(_period).future);
    final months = BsCalendar.groupSalesByBsMonth(daily);
    if (!mounted) return;
    await ref
        .read(exportShareServiceProvider)
        .shareCsv(
          filename:
              'businesssajilo-fiscal-summary-${DateTime.now().toIso8601String().split('T').first}.csv',
          subject: l10n.fiscalSummary,
          rows: fiscalSummaryCsvRows([
            for (final m in months)
              (
                BsCalendar.monthLabel(m.month, locale: locale),
                m.billCount,
                m.totalSales,
              ),
          ]),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final salesAsync = ref.watch(salesDailyRangeProvider(_period));
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
              onPressed: _exportCsv,
              icon: const Icon(Icons.download_outlined),
            ),
          ],
        ),
        const SizedBox(height: 16),
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
            final months = BsCalendar.groupSalesByBsMonth(points);
            if (months.isEmpty) {
              return EmptyState(
                icon: Icons.calendar_month_outlined,
                message: l10n.noSalesInPeriod,
              );
            }
            final total = months.fold<int>(0, (sum, m) => sum + m.totalSales);
            final totalBills = months.fold<int>(0, (sum, m) => sum + m.billCount);
            final activeMonths = months.where((m) => m.totalSales > 0).length;
            final avgMonthly = activeMonths > 0 ? (total ~/ activeMonths) : 0;
            final maxMonth = months.reduce(
              (a, b) => a.totalSales > b.totalSales ? a : b,
            );
            final maxSales = maxMonth.totalSales;
            final locale = Localizations.localeOf(context);

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
                      label: l10n.fiscalYearTotal,
                      value: formatNpr(Paisa(total), showPaisa: false),
                      icon: Icons.calendar_today_outlined,
                      color: BsColors.primary,
                    ),
                    _KpiCard(
                      label: l10n.totalInvoices,
                      value: '$totalBills',
                      icon: Icons.receipt_long_outlined,
                      color: Colors.indigo,
                    ),
                    _KpiCard(
                      label: l10n.monthlyAverage,
                      value: formatNpr(Paisa(avgMonthly), showPaisa: false),
                      icon: Icons.auto_graph_outlined,
                      color: Colors.teal,
                    ),
                    _KpiCard(
                      label: l10n.bestMonth,
                      value: maxSales > 0
                          ? BsCalendar.monthLabel(maxMonth.month, locale: locale)
                          : '—',
                      icon: Icons.emoji_events_outlined,
                      color: Colors.amber.shade800,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.fiscalMonthlySales,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
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
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: months.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final m = months[index];
                      final ratio = maxSales > 0 ? (m.totalSales / maxSales) : 0.0;
                      final monthName = BsCalendar.monthLabel(
                        m.month,
                        locale: locale,
                      );
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  monthName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                MoneyText(
                                  Paisa(m.totalSales),
                                  showPaisa: false,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${m.billCount} ${l10n.bills.toLowerCase()}',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: BsColors.outline),
                                ),
                                if (total > 0 && m.totalSales > 0)
                                  Text(
                                    '${((m.totalSales / total) * 100).toStringAsFixed(1)}%',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: BsColors.outline),
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
                                  m == maxMonth && maxSales > 0
                                      ? Colors.amber.shade700
                                      : BsColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );

    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.fiscalSummary)),
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
