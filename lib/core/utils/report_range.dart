import '../../domain/enums.dart';

class ReportDateRange {
  const ReportDateRange({required this.from, required this.to});

  final DateTime from;
  final DateTime to;
}

ReportDateRange dateRangeFor(ReportRange range, {DateTime? now}) {
  final utc = (now ?? DateTime.now()).toUtc();
  final todayStart = DateTime.utc(utc.year, utc.month, utc.day);
  return switch (range) {
    ReportRange.today => ReportDateRange(
        from: todayStart,
        to: todayStart.add(const Duration(days: 1)),
      ),
    ReportRange.week => ReportDateRange(
        from: todayStart.subtract(const Duration(days: 6)),
        to: todayStart.add(const Duration(days: 1)),
      ),
    ReportRange.month => ReportDateRange(
        from: DateTime.utc(utc.year, utc.month, 1),
        to: todayStart.add(const Duration(days: 1)),
      ),
    ReportRange.last7Days => ReportDateRange(
        from: todayStart.subtract(const Duration(days: 6)),
        to: todayStart.add(const Duration(days: 1)),
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
