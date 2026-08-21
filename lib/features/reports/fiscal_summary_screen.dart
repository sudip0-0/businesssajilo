import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/export/export_share_service.dart';
import '../../core/export/report_csv_export.dart';
import '../../core/l10n/app_localizations.dart';
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
        Text(
          l10n.fiscalMonthlySales,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        salesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorState(
            message: l10n.loadingFailed,
            onRetry: () => ref.invalidate(salesDailyRangeProvider(_period)),
          ),
          data: (points) {
            final months = BsCalendar.groupSalesByBsMonth(points);
            if (months.isEmpty) {
              return EmptyState(icon: Icons.calendar_month_outlined, message: l10n.noSalesInPeriod);
            }
            final total = months.fold<int>(0, (sum, m) => sum + m.totalSales);
            final locale = Localizations.localeOf(context);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.totalSales, style: Theme.of(context).textTheme.titleSmall),
                MoneyText(
                  Paisa(total),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                for (final m in months)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      BsCalendar.monthLabel(m.month, locale: locale),
                    ),
                    subtitle: Text('${m.billCount} ${l10n.bills}'),
                    trailing: MoneyText(
                      Paisa(m.totalSales),
                      showPaisa: false,
                      style: Theme.of(context).textTheme.titleSmall,
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
