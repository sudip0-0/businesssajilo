import 'package:businesssajilo/core/utils/report_range.dart';
import 'package:businesssajilo/domain/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 2026-06-11 15:30 UTC == 2026-06-11 21:15 NPT.
  final now = DateTime.utc(2026, 6, 11, 15, 30);
  // NPT midnight of Jun 11 expressed as a UTC instant.
  final todayStartUtc = DateTime.utc(2026, 6, 10, 18, 15);
  final tomorrowStartUtc = DateTime.utc(2026, 6, 11, 18, 15);

  test('nptDayStartUtc returns NPT midnight as UTC instant', () {
    expect(nptDayStartUtc(now: now), todayStartUtc);
  });

  test('nptDayStartUtc rolls to next NPT day after 18:15 UTC', () {
    // 18:30 UTC == 00:15 NPT next day.
    final late = DateTime.utc(2026, 6, 11, 18, 30);
    expect(nptDayStartUtc(now: late), tomorrowStartUtc);
  });

  test('nptDateString formats the NPT calendar date', () {
    expect(nptDateString(now), '2026-06-11');
    expect(nptDateString(DateTime.utc(2026, 6, 11, 18, 30)), '2026-06-12');
    expect(nptDateString(DateTime.utc(2026, 6, 10, 18, 0)), '2026-06-10');
  });

  test('today range spans the NPT day as UTC instants', () {
    final range = dateRangeFor(ReportRange.today, now: now);
    expect(range.from, todayStartUtc);
    expect(range.to, tomorrowStartUtc);
  });

  test('week range covers 7 NPT days ending today', () {
    final range = dateRangeFor(ReportRange.week, now: now);
    expect(range.from, DateTime.utc(2026, 6, 4, 18, 15));
    expect(range.to, tomorrowStartUtc);
  });

  test('month range starts first of NPT month', () {
    final range = dateRangeFor(ReportRange.month, now: now);
    expect(range.from, DateTime.utc(2026, 5, 31, 18, 15));
    expect(range.to, tomorrowStartUtc);
  });

  test('last7Days matches week window', () {
    final week = dateRangeFor(ReportRange.week, now: now);
    final last7 = dateRangeFor(ReportRange.last7Days, now: now);
    expect(last7.from, week.from);
    expect(last7.to, week.to);
  });
}
