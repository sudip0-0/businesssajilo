import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/utils/report_range.dart';
import '../../../../features/reports/report_period.dart';
import '../../../theme/web_palette.dart';
import '../../../theme/web_tokens.dart';

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
        start: DateTime(initialStart.year, initialStart.month, initialStart.day),
        end: DateTime(initialEnd.year, initialEnd.month, initialEnd.day),
      ),
      helpText: l10n.periodCustom,
      cancelText: l10n.cancel,
    );
    if (range == null) return;
    onChanged(
      ReportPeriod.custom(fromDate: range.start, toDate: range.end),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final compact = context.isWebCompact;
    final presets = const [
      ReportPeriodPreset.today,
      ReportPeriodPreset.last7Days,
      ReportPeriodPreset.last30Days,
      ReportPeriodPreset.thisMonth,
    ];

    if (compact) {
      return Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<ReportPeriodPreset>(
              initialValue: value.preset == ReportPeriodPreset.custom
                  ? ReportPeriodPreset.custom
                  : value.preset,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              items: [
                for (final p in presets)
                  DropdownMenuItem(value: p, child: Text(_label(l10n, p))),
                DropdownMenuItem(
                  value: ReportPeriodPreset.custom,
                  child: Text(l10n.periodCustom),
                ),
              ],
              onChanged: (preset) async {
                if (preset == null) return;
                if (preset == ReportPeriodPreset.custom) {
                  await _pickCustom(context);
                } else {
                  onChanged(ReportPeriod.preset(preset));
                }
              },
            ),
          ),
          if (value.preset == ReportPeriodPreset.custom) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _customRangeLabel(value),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: WebPalette.inkSoft,
                ),
              ),
            ),
          ],
        ],
      );
    }

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
            PhosphorIconsRegular.calendarBlank,
            size: 16,
            color: value.preset == ReportPeriodPreset.custom
                ? WebPalette.navy
                : WebPalette.inkSoft,
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
