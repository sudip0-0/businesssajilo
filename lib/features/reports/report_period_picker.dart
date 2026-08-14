import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/utils/report_range.dart';
import 'report_period.dart';

/// Theme-agnostic period picker (today / 7d / 30d / month / custom).
///
/// Lives under `lib/features` so mobile reports can share [ReportPeriod]
/// without importing `lib/web`.
class ReportPeriodPicker extends StatelessWidget {
  const ReportPeriodPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final ReportPeriod value;
  final ValueChanged<ReportPeriod> onChanged;

  String _label(AppLocalizations l10n, ReportPeriodPreset preset) =>
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
    final initialStart = value.from.toUtc().add(nptOffset);
    final initialEnd = value.to
        .toUtc()
        .add(nptOffset)
        .subtract(const Duration(days: 1));

    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(nowNpt.year - 3),
      lastDate: DateTime(nowNpt.year, nowNpt.month, nowNpt.day),
      initialDateRange: DateTimeRange(
        start: DateTime(
          initialStart.year,
          initialStart.month,
          initialStart.day,
        ),
        end: DateTime(initialEnd.year, initialEnd.month, initialEnd.day),
      ),
      helpText: l10n.periodCustom,
      cancelText: l10n.cancel,
    );
    if (range == null) return;
    onChanged(ReportPeriod.custom(fromDate: range.start, toDate: range.end));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final presets = const [
      ReportPeriodPreset.today,
      ReportPeriodPreset.last7Days,
      ReportPeriodPreset.last30Days,
      ReportPeriodPreset.thisMonth,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final p in presets)
          ChoiceChip(
            label: Text(_label(l10n, p)),
            selected: value.preset == p,
            onSelected: (_) => onChanged(ReportPeriod.preset(p)),
          ),
        ChoiceChip(
          avatar: Icon(
            Icons.calendar_today_outlined,
            size: 16,
            color: value.preset == ReportPeriodPreset.custom
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          label: Text(
            value.preset == ReportPeriodPreset.custom
                ? _customRangeLabel(value)
                : l10n.periodCustom,
          ),
          selected: value.preset == ReportPeriodPreset.custom,
          onSelected: (_) => _pickCustom(context),
        ),
      ],
    );
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
}
