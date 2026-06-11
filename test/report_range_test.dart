import 'package:businesssajilo/core/utils/report_range.dart';
import 'package:businesssajilo/domain/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 6, 11, 15, 30);

  test('today range is UTC midnight to next midnight', () {
    final range = dateRangeFor(ReportRange.today, now: now);
    expect(range.from, DateTime.utc(2026, 6, 11));
    expect(range.to, DateTime.utc(2026, 6, 12));
  });

  test('week range covers 7 days ending today', () {
    final range = dateRangeFor(ReportRange.week, now: now);
    expect(range.from, DateTime.utc(2026, 6, 5));
    expect(range.to, DateTime.utc(2026, 6, 12));
  });

  test('month range starts first of month', () {
    final range = dateRangeFor(ReportRange.month, now: now);
    expect(range.from, DateTime.utc(2026, 6, 1));
    expect(range.to, DateTime.utc(2026, 6, 12));
  });

  test('last7Days matches week window', () {
    final week = dateRangeFor(ReportRange.week, now: now);
    final last7 = dateRangeFor(ReportRange.last7Days, now: now);
    expect(last7.from, week.from);
    expect(last7.to, week.to);
  });
}
