import 'package:businesssajilo/core/utils/report_range.dart';
import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/features/reports/report_period.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Fixed UTC instant → NPT 2026-03-15 12:00.
  final now = DateTime.utc(2026, 3, 15, 6, 15);

  test('preset last7Days uses NPT day bounds', () {
    final period = ReportPeriod.preset(ReportPeriodPreset.last7Days, now: now);
    expect(period.from, dateRangeFor(ReportRange.last7Days, now: now).from);
    expect(period.to, dateRangeFor(ReportRange.last7Days, now: now).to);
    expect(period.queryValue, '7d');
  });

  test('custom period is inclusive NPT calendar dates as [from, to)', () {
    final period = ReportPeriod.custom(
      fromDate: DateTime(2026, 3, 1),
      toDate: DateTime(2026, 3, 10),
    );
    expect(nptDateString(period.from), '2026-03-01');
    // to is exclusive → calendar day after 2026-03-10
    expect(nptDateString(period.to), '2026-03-11');
    expect(period.preset, ReportPeriodPreset.custom);
  });

  test('previousEqualLength mirrors duration before from', () {
    final period = ReportPeriod.preset(ReportPeriodPreset.last7Days, now: now);
    final prev = period.previousEqualLength;
    expect(prev.to, period.from);
    expect(prev.to.difference(prev.from), period.to.difference(period.from));
  });

  test('fromQuery maps aliases and defaults to last7Days', () {
    expect(
      ReportPeriod.fromQuery('today', now: now).preset,
      ReportPeriodPreset.today,
    );
    expect(
      ReportPeriod.fromQuery('month', now: now).preset,
      ReportPeriodPreset.thisMonth,
    );
    expect(
      ReportPeriod.fromQuery(null, now: now).preset,
      ReportPeriodPreset.last7Days,
    );
  });

  test('equality keys Riverpod families', () {
    final a = ReportPeriod.preset(ReportPeriodPreset.today, now: now);
    final b = ReportPeriod.preset(ReportPeriodPreset.today, now: now);
    final c = ReportPeriod.preset(ReportPeriodPreset.last30Days, now: now);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a == c, isFalse);
  });
}
