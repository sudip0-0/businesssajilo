import 'package:businesssajilo/core/utils/bs_calendar.dart';
import 'package:businesssajilo/core/utils/report_range.dart';
import 'package:businesssajilo/features/reports/report_period.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 7, 20); // Shrawan 2083 (fiscal year start).

  group('ReportPeriod BS presets', () {
    test('bsThisMonth covers the current BS month', () {
      final period = ReportPeriod.preset(
        ReportPeriodPreset.bsThisMonth,
        now: now,
      );
      expect(period.from, BsCalendar.monthRange(BsCalendar.currentBsMonth(now: now)).from);
      expect(period.to, BsCalendar.monthRange(BsCalendar.currentBsMonth(now: now)).to);
    });

    test('bsLastMonth ends where bsThisMonth begins', () {
      final last = ReportPeriod.preset(ReportPeriodPreset.bsLastMonth, now: now);
      final current = ReportPeriod.preset(
        ReportPeriodPreset.bsThisMonth,
        now: now,
      );
      expect(last.to, current.from);
      expect(last.to.isAfter(last.from), isTrue);
    });

    test('bsFiscalYear spans Shrawan-to-Ashadh', () {
      final fy = ReportPeriod.preset(ReportPeriodPreset.bsFiscalYear, now: now);
      final startBs = BsCalendar.bsDateOf(fy.from.add(nptOffset));
      expect(startBs.year, 2083);
      expect(startBs.month, BsCalendar.fiscalYearStartMonth);
      expect(startBs.day, 1);
      // ~12 months.
      expect(fy.to.difference(fy.from).inDays, inInclusiveRange(363, 372));
    });

    test('query round-trips for all BS presets', () {
      for (final preset in [
        ReportPeriodPreset.bsThisMonth,
        ReportPeriodPreset.bsLastMonth,
        ReportPeriodPreset.bsFiscalYear,
        ReportPeriodPreset.bsLastFiscalYear,
      ]) {
        final period = ReportPeriod.preset(preset, now: now);
        final parsed = ReportPeriod.fromQuery(period.queryValue, now: now);
        expect(parsed.preset, preset, reason: period.queryValue);
        expect(parsed.from, period.from, reason: period.queryValue);
        expect(parsed.to, period.to, reason: period.queryValue);
      }
    });
  });
}
