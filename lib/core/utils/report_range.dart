import '../../domain/enums.dart';
import '../../domain/models/sales_period_point.dart';

/// Nepal Time fixed offset (UTC+05:45). No DST.
const Duration nptOffset = Duration(hours: 5, minutes: 45);

/// Start of the current Nepal-time day, expressed as a UTC instant.
DateTime nptDayStartUtc({DateTime? now}) {
  final npt = (now ?? DateTime.now()).toUtc().add(nptOffset);
  return DateTime.utc(npt.year, npt.month, npt.day).subtract(nptOffset);
}

/// Formats the Nepal-time calendar date of [instant] as 'yyyy-MM-dd'.
String nptDateString(DateTime instant) {
  final npt = instant.toUtc().add(nptOffset);
  return '${npt.year.toString().padLeft(4, '0')}'
      '-${npt.month.toString().padLeft(2, '0')}'
      '-${npt.day.toString().padLeft(2, '0')}';
}

class ReportDateRange {
  const ReportDateRange({required this.from, required this.to});

  /// UTC instants delimiting [from, to).
  final DateTime from;
  final DateTime to;
}

/// Computes report windows on Nepal-time day boundaries, returned as UTC
/// instants suitable for timestamptz queries.
ReportDateRange dateRangeFor(ReportRange range, {DateTime? now}) {
  final npt = (now ?? DateTime.now()).toUtc().add(nptOffset);
  DateTime toUtcInstant(DateTime nptWallClock) =>
      nptWallClock.subtract(nptOffset);
  final todayStartNpt = DateTime.utc(npt.year, npt.month, npt.day);
  final todayStart = toUtcInstant(todayStartNpt);
  final tomorrowStart = toUtcInstant(
    todayStartNpt.add(const Duration(days: 1)),
  );
  return switch (range) {
    ReportRange.today => ReportDateRange(from: todayStart, to: tomorrowStart),
    ReportRange.week => ReportDateRange(
      from: toUtcInstant(todayStartNpt.subtract(const Duration(days: 6))),
      to: tomorrowStart,
    ),
    ReportRange.month => ReportDateRange(
      from: toUtcInstant(DateTime.utc(npt.year, npt.month, 1)),
      to: tomorrowStart,
    ),
    ReportRange.last7Days => ReportDateRange(
      from: toUtcInstant(todayStartNpt.subtract(const Duration(days: 6))),
      to: tomorrowStart,
    ),
  };
}

String agingBucketLabel(String bucket) => switch (bucket) {
  '0_30' => '0_30',
  '31_60' => '31_60',
  '60_plus' => '60_plus',
  _ => bucket,
};

String bucketFromAgeDays(int ageDays) {
  if (ageDays <= 30) return '0_30';
  if (ageDays <= 60) return '31_60';
  return '60_plus';
}

/// Fills missing calendar days in [points] between [from] and [to] (exclusive).
List<SalesPeriodPoint> fillSalesDailyGaps({
  required List<SalesPeriodPoint> points,
  required DateTime from,
  required DateTime to,
}) {
  final byDate = {for (final p in points) nptDateString(p.saleDate): p};
  final filled = <SalesPeriodPoint>[];
  var day = from;
  while (day.isBefore(to)) {
    final key = nptDateString(day);
    filled.add(byDate[key] ?? SalesPeriodPoint(saleDate: day));
    day = day.add(const Duration(days: 1));
  }
  return filled;
}
