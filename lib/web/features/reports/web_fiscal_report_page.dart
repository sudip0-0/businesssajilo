import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/export/export_share_service.dart';
import '../../../core/export/report_csv_export.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/bs_calendar.dart';
import '../../../core/utils/money.dart';
import '../../../features/reports/providers.dart';
import '../../../features/reports/report_period.dart';
import '../../layout/web_bento_grid.dart';
import '../../theme/web_palette.dart';
import '../../ui/web_empty_state.dart';
import '../../ui/web_stat_tile.dart';
import '../web_page_scaffold.dart';
import 'widgets/report_filter_bar.dart';
import 'widgets/report_period_picker.dart';

/// Web host for sales grouped by BS month.
class WebFiscalReportPage extends ConsumerStatefulWidget {
  const WebFiscalReportPage({super.key, this.initialPeriod});

  final String? initialPeriod;

  @override
  ConsumerState<WebFiscalReportPage> createState() =>
      _WebFiscalReportPageState();
}

class _WebFiscalReportPageState extends ConsumerState<WebFiscalReportPage> {
  late ReportPeriod _period;

  @override
  void initState() {
    super.initState();
    _period = ReportPeriod.fromQuery(
      widget.initialPeriod,
    );
    if (widget.initialPeriod == null) {
      _period = ReportPeriod.preset(ReportPeriodPreset.bsFiscalYear);
    }
  }

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

    return WebPageScaffold(
      title: l10n.fiscalSummary,
      breadcrumbs: [l10n.reports, l10n.fiscalSummary],
      actions: [
        IconButton(
          tooltip: l10n.exportCsv,
          onPressed: _exportCsv,
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
          ),
          const SizedBox(height: 20),
          Expanded(
            child: salesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => WebEmptyState(
                icon: PhosphorIconsRegular.warningCircle,
                message: l10n.loadingFailed,
                actionLabel: l10n.tryAgain,
                onAction: () =>
                    ref.invalidate(salesDailyRangeProvider(_period)),
              ),
              data: (points) {
                final months = BsCalendar.groupSalesByBsMonth(points);
                if (months.isEmpty) {
                  return WebEmptyState(
                    icon: PhosphorIconsRegular.calendarBlank,
                    message: l10n.noSalesInPeriod,
                  );
                }
                final total = months.fold<int>(
                  0,
                  (sum, m) => sum + m.totalSales,
                );
                final totalBills = months.fold<int>(
                  0,
                  (sum, m) => sum + m.billCount,
                );
                final activeMonths = months.where((m) => m.totalSales > 0).length;
                final avgMonthly = activeMonths > 0 ? (total ~/ activeMonths) : 0;
                final maxMonth = months.reduce(
                  (a, b) => a.totalSales > b.totalSales ? a : b,
                );
                final maxSales = maxMonth.totalSales;
                final locale = Localizations.localeOf(context);

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      WebBentoGrid(
                        columns: 4,
                        children: [
                          WebStatTile(
                            label: l10n.fiscalYearTotal,
                            value: formatNpr(Paisa(total), showPaisa: false),
                            icon: PhosphorIconsRegular.calendar,
                          ),
                          WebStatTile(
                            label: l10n.totalInvoices,
                            value: '$totalBills',
                            icon: PhosphorIconsRegular.receipt,
                          ),
                          WebStatTile(
                            label: l10n.monthlyAverage,
                            value: formatNpr(Paisa(avgMonthly), showPaisa: false),
                            icon: PhosphorIconsRegular.chartLineUp,
                          ),
                          WebStatTile(
                            label: l10n.bestMonth,
                            value: maxSales > 0
                                ? BsCalendar.monthLabel(maxMonth.month, locale: locale)
                                : '—',
                            icon: PhosphorIconsRegular.trophy,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      WebBentoTile(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.fiscalMonthlySales,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                            for (var i = 0; i < months.length; i++)
                              _MonthlySalesRow(
                                monthData: months[i],
                                maxSales: maxSales,
                                locale: locale,
                                isLast: i == months.length - 1,
                                isMax: months[i] == maxMonth && maxSales > 0,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlySalesRow extends StatelessWidget {
  const _MonthlySalesRow({
    required this.monthData,
    required this.maxSales,
    required this.locale,
    required this.isLast,
    required this.isMax,
  });

  final BsMonthlyPoint monthData;
  final int maxSales;
  final Locale locale;
  final bool isLast;
  final bool isMax;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ratio = maxSales > 0 ? (monthData.totalSales / maxSales) : 0.0;
    final monthName = BsCalendar.monthLabel(monthData.month, locale: locale);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 140,
                child: Text(
                  monthName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(
                width: 100,
                child: Text(
                  '${monthData.billCount} ${l10n.bills.toLowerCase()}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: WebPalette.inkSoft),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio.clamp(0.0, 1.0),
                    minHeight: 12,
                    backgroundColor: WebPalette.paperDeep,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isMax ? WebPalette.warning : WebPalette.navy,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 120,
                child: Text(
                  formatNpr(
                    Paisa(monthData.totalSales),
                    showPaisa: false,
                  ),
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1),
      ],
    );
  }
}
