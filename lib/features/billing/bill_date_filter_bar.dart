import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/utils/report_range.dart';
import '../reports/report_period.dart';

/// Horizontal date chips for the billing list: all dates or a [ReportPeriod].
class BillDateFilterBar extends StatelessWidget {
  const BillDateFilterBar({
    super.key,
    required this.value,
    required this.onChanged,
  });

  /// `null` means no date filter (all dates).
  final ReportPeriod? value;
  final ValueChanged<ReportPeriod?> onChanged;

  String _presetLabel(AppLocalizations l10n, ReportPeriodPreset preset) =>
      switch (preset) {
        ReportPeriodPreset.today => l10n.periodToday,
        ReportPeriodPreset.last7Days => l10n.periodLast7Days,
        ReportPeriodPreset.last30Days => l10n.periodLast30Days,
        ReportPeriodPreset.thisMonth => l10n.periodThisMonth,
        ReportPeriodPreset.custom => l10n.periodCustom,
      };

  Future<void> _pickCustom(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final nowNpt = DateTime.now().toUtc().add(nptOffset);
    final current = value;
    final initialStart = current == null
        ? DateTime(nowNpt.year, nowNpt.month, nowNpt.day)
        : () {
            final npt = current.from.toUtc().add(nptOffset);
            return DateTime(npt.year, npt.month, npt.day);
          }();
    final initialEnd = current == null
        ? DateTime(nowNpt.year, nowNpt.month, nowNpt.day)
        : () {
            final npt = current.to
                .toUtc()
                .add(nptOffset)
                .subtract(const Duration(days: 1));
            return DateTime(npt.year, npt.month, npt.day);
          }();

    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(nowNpt.year - 3),
      lastDate: DateTime(nowNpt.year, nowNpt.month, nowNpt.day),
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
      helpText: l10n.periodCustom,
      cancelText: l10n.cancel,
    );
    if (range == null) return;
    onChanged(ReportPeriod.custom(fromDate: range.start, toDate: range.end));
  }

  String _customRangeLabel(ReportPeriod period) {
    final fmt = DateFormat.MMMd();
    final from = period.from.toUtc().add(nptOffset);
    final to = period.to
        .toUtc()
        .add(nptOffset)
        .subtract(const Duration(days: 1));
    return '${fmt.format(DateTime(from.year, from.month, from.day))}'
        ' – ${fmt.format(DateTime(to.year, to.month, to.day))}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const presets = [
      ReportPeriodPreset.today,
      ReportPeriodPreset.last7Days,
      ReportPeriodPreset.last30Days,
      ReportPeriodPreset.thisMonth,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(l10n.periodAllDates),
              selected: value == null,
              onSelected: (_) => onChanged(null),
            ),
          ),
          for (final preset in presets)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(_presetLabel(l10n, preset)),
                selected: value?.preset == preset,
                onSelected: (_) => onChanged(ReportPeriod.preset(preset)),
              ),
            ),
          FilterChip(
            avatar: Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: value?.preset == ReportPeriodPreset.custom
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
            ),
            label: Text(
              value?.preset == ReportPeriodPreset.custom
                  ? _customRangeLabel(value!)
                  : l10n.periodCustom,
            ),
            selected: value?.preset == ReportPeriodPreset.custom,
            onSelected: (_) => _pickCustom(context),
          ),
        ],
      ),
    );
  }
}
