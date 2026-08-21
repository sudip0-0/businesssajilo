import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/export/export_share_service.dart';
import '../../../core/export/report_csv_export.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/bs_calendar.dart';
import '../../../core/utils/money.dart';
import '../../../features/reports/fiscal_summary_screen.dart';
import '../../../features/reports/providers.dart';
import '../../../features/reports/report_period.dart';
import '../../theme/web_palette.dart';
import '../../ui/web_empty_state.dart';
import '../web_page_scaffold.dart';
import 'widgets/report_filter_bar.dart';
import 'widgets/report_period_picker.dart';

/// Web host for [FiscalSummaryScreen]: sales grouped by BS month.
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
      // Default to the current fiscal year on this page.
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
                final locale = Localizations.localeOf(context);
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${l10n.totalSales}: '
                        '${formatNpr(Paisa(total), showPaisa: false)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      for (final m in months)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  BsCalendar.monthLabel(m.month, locale: locale),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(color: WebPalette.ink),
                                ),
                              ),
                              Text(
                                '${m.billCount} ${l10n.bills.toLowerCase()}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: WebPalette.inkSoft),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                formatNpr(
                                  Paisa(m.totalSales),
                                  showPaisa: false,
                                ),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
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
