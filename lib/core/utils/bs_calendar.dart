import 'dart:ui' show Locale;

import 'package:nepali_utils/nepali_utils.dart';

import '../../domain/models/sales_period_point.dart';
import 'report_range.dart';

/// Bikram Sambat month used as a fiscal-summary bucket.
class BsMonthlyPoint {
  const BsMonthlyPoint({
    required this.month,
    this.totalSales = 0,
    this.billCount = 0,
  });

  /// First day of the BS month (NepaliDateTime with day = 1).
  final NepaliDateTime month;
  final int totalSales;
  final int billCount;
}

/// Bikram Sambat calendar windows for reports.
///
/// Conversions are timezone-safe: AD→BS uses the package's UTC-based
/// conversion; BS→AD results are treated as NPT wall-clock dates and turned
/// into UTC instants on NPT midnight boundaries (`[from, to)`), matching
/// `dateRangeFor` so they feed the same timestamptz RPCs as AD reports.
abstract final class BsCalendar {
  /// Fiscal year starts in Shrawan (BS month 4) and ends in Ashadh.
  static const fiscalYearStartMonth = 4;

  /// Converts a UTC instant to its BS calendar date (time-of-day dropped).
  static NepaliDateTime bsDateOf(DateTime utcInstant) {
    final bs = utcInstant.toUtc().toNepaliDateTime();
    return NepaliDateTime(bs.year, bs.month, bs.day);
  }

  /// UTC instant of NPT midnight starting the given BS calendar date.
  ///
  /// Uses only the package's AD→BS conversion (its BS→AD path applies a
  /// timezone-dependent day adjustment that breaks round-trips on +05:45
  /// machines). The AD↔BS mapping is monotonic, so binary-search the UTC
  /// instant whose NPT calendar date equals [bs].
  static DateTime instantFromBsDate(NepaliDateTime bs) {
    var lo = DateTime.utc(bs.year - 58, 1, 1);
    var hi = DateTime.utc(bs.year - 54, 12, 31);
    while (lo.isBefore(hi)) {
      final mid = lo.add(
        Duration(days: hi.difference(lo).inDays ~/ 2),
      );
      if (_compareBs(bsDateOf(mid), bs) < 0) {
        lo = mid.add(const Duration(days: 1));
      } else {
        hi = mid;
      }
    }
    // Snap to NPT midnight of the matched calendar date.
    final nptWall = lo.toUtc().add(nptOffset);
    return DateTime.utc(
      nptWall.year,
      nptWall.month,
      nptWall.day,
    ).subtract(nptOffset);
  }

  static int _compareBs(NepaliDateTime a, NepaliDateTime b) {
    if (a.year != b.year) return a.year.compareTo(b.year);
    if (a.month != b.month) return a.month.compareTo(b.month);
    return a.day.compareTo(b.day);
  }

  static NepaliDateTime _firstOfMonth(NepaliDateTime bs) =>
      NepaliDateTime(bs.year, bs.month, 1);

  static NepaliDateTime _nextMonth(NepaliDateTime bs) => bs.month == 12
      ? NepaliDateTime(bs.year + 1, 1, 1)
      : NepaliDateTime(bs.year, bs.month + 1, 1);

  static NepaliDateTime _previousMonth(NepaliDateTime bs) => bs.month == 1
      ? NepaliDateTime(bs.year - 1, 12, 1)
      : NepaliDateTime(bs.year, bs.month - 1, 1);

  /// Current BS month (day set to 1).
  static NepaliDateTime currentBsMonth({DateTime? now}) =>
      _firstOfMonth(bsDateOf(now ?? DateTime.now()));

  /// Previous BS month (day set to 1).
  static NepaliDateTime previousBsMonth({DateTime? now}) =>
      _previousMonth(currentBsMonth(now: now));

  /// `[from, to)` UTC window covering the whole given BS month.
  static ReportDateRange monthRange(NepaliDateTime monthStart) {
    assert(monthStart.day == 1, 'Pass the first day of the BS month');
    return ReportDateRange(
      from: instantFromBsDate(monthStart),
      to: instantFromBsDate(_nextMonth(monthStart)),
    );
  }

  /// Fiscal year (Shrawan–Ashadh) containing [bs], as start BS year.
  /// E.g. BS 2083 Shrawan → FY starting in year 2083 (ends Ashadh 2084).
  static int fiscalYearStartYearOf(NepaliDateTime bs) =>
      bs.month >= fiscalYearStartMonth ? bs.year : bs.year - 1;

  /// Current fiscal year's starting BS year.
  static int currentFiscalYearStartYear({DateTime? now}) =>
      fiscalYearStartYearOf(bsDateOf(now ?? DateTime.now()));

  /// `[from, to)` UTC window for the fiscal year starting in BS [startYear].
  static ReportDateRange fiscalYearRange(int startYear) => ReportDateRange(
    from: instantFromBsDate(NepaliDateTime(startYear, fiscalYearStartMonth, 1)),
    to: instantFromBsDate(
      NepaliDateTime(startYear + 1, fiscalYearStartMonth, 1),
    ),
  );

  /// Groups daily sales points into BS months. Points outside the covered
  /// months are ignored; months with no sales are omitted.
  static List<BsMonthlyPoint> groupSalesByBsMonth(
    List<SalesPeriodPoint> points,
  ) {
    final byMonth = <String, BsMonthlyPoint>{};
    for (final point in points) {
      final month = _firstOfMonth(bsDateOf(point.saleDate));
      final key = '${month.year}-${month.month}';
      final existing = byMonth[key];
      byMonth[key] = BsMonthlyPoint(
        month: month,
        totalSales: (existing?.totalSales ?? 0) + point.totalSales,
        billCount: (existing?.billCount ?? 0) + point.billCount,
      );
    }
    final months = byMonth.values.toList()
      ..sort((a, b) {
        final byYear = a.month.year.compareTo(b.month.year);
        return byYear != 0 ? byYear : a.month.month.compareTo(b.month.month);
      });
    return months;
  }

  /// e.g. "२०८३ असार" (Nepali default) or "2083 Asar" for English locale.
  static String monthLabel(NepaliDateTime monthStart, {Locale? locale}) {
    final language =
        locale?.languageCode == 'en' ? Language.english : Language.nepali;
    return NepaliDateFormat('yyyy MMMM', language).format(monthStart);
  }
}
