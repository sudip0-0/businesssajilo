import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/bs_breakpoints.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/ui/bs_sales_line_chart.dart';
import '../../../../core/ui/error_state.dart';
import '../../../../core/utils/report_range.dart';
import '../../../../domain/enums.dart';
import '../../../../domain/models/sales_period_point.dart';
import '../../../layout/web_bento_grid.dart';
import '../../../theme/web_palette.dart';

/// Sales performance chart section for the owner web dashboard.
class WebDashboardSalesChart extends ConsumerWidget {
  const WebDashboardSalesChart({
    super.key,
    required this.weeklyChart,
    required this.chartData,
    required this.chartRange,
    required this.onRangeChanged,
    required this.onRetry,
  });

  final bool weeklyChart;
  final AsyncValue<List<SalesPeriodPoint>> chartData;
  final ReportRange chartRange;
  final ValueChanged<bool> onRangeChanged;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return WebBentoTile(
      minHeight: 320,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, headerConstraints) {
              final stackHeader =
                  headerConstraints.maxWidth < BsBreakpoints.phoneCompact;
              final titleBlock = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.salesPerformance,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    weeklyChart
                        ? l10n.salesPerformanceSubtitle
                        : l10n.salesPerformanceSubtitleMonthly,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: WebPalette.inkSoft),
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
                selected: {weeklyChart},
                onSelectionChanged: (s) => onRangeChanged(s.first),
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
                period: weeklyChart
                    ? SalesChartPeriod.weekly
                    : SalesChartPeriod.monthly,
              );
            },
            loading: () => const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => SizedBox(
              height: 200,
              child: ErrorState(
                message: l10n.loadingFailed,
                onRetry: onRetry,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
