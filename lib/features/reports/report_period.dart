import '../../core/utils/bs_calendar.dart';
import '../../core/utils/report_range.dart';
import '../../domain/enums.dart';

/// Preset or custom date window for owner web reports.
///
/// `bs*` presets are Bikram Sambat calendar windows (NPT day boundaries)
/// converted to AD UTC instants; they reuse the same report RPCs.
enum ReportPeriodPreset {
  today,
  last7Days,
  last30Days,
  thisMonth,
  bsThisMonth,
  bsLastMonth,
  bsFiscalYear,
  bsLastFiscalYear,
  custom,
}

/// Immutable period selection used to key Riverpod report providers.
class ReportPeriod {
  const ReportPeriod._({
    required this.preset,
    required this.from,
    required this.to,
  });

  final ReportPeriodPreset preset;

  /// UTC instants delimiting [from, to).
  final DateTime from;
  final DateTime to;

  factory ReportPeriod.preset(ReportPeriodPreset preset, {DateTime? now}) {
    assert(preset != ReportPeriodPreset.custom);
    final range = switch (preset) {
      ReportPeriodPreset.today => dateRangeFor(ReportRange.today, now: now),
      ReportPeriodPreset.last7Days => dateRangeFor(
        ReportRange.last7Days,
        now: now,
      ),
      ReportPeriodPreset.last30Days => dateRangeFor(
        ReportRange.last30Days,
        now: now,
      ),
      ReportPeriodPreset.thisMonth => dateRangeFor(ReportRange.month, now: now),
      ReportPeriodPreset.bsThisMonth => BsCalendar.monthRange(
        BsCalendar.currentBsMonth(now: now),
      ),
      ReportPeriodPreset.bsLastMonth => BsCalendar.monthRange(
        BsCalendar.previousBsMonth(now: now),
      ),
      ReportPeriodPreset.bsFiscalYear => BsCalendar.fiscalYearRange(
        BsCalendar.currentFiscalYearStartYear(now: now),
      ),
      ReportPeriodPreset.bsLastFiscalYear => BsCalendar.fiscalYearRange(
        BsCalendar.currentFiscalYearStartYear(now: now) - 1,
      ),
      ReportPeriodPreset.custom => throw StateError('Use ReportPeriod.custom'),
    };
    return ReportPeriod._(preset: preset, from: range.from, to: range.to);
  }

  /// Custom inclusive NPT calendar dates converted to UTC [from, to).
  factory ReportPeriod.custom({
    required DateTime fromDate,
    required DateTime toDate,
  }) {
    // Treat inputs as NPT calendar dates (year/month/day only).
    final fromNpt = DateTime.utc(fromDate.year, fromDate.month, fromDate.day);
    final toNptExclusive = DateTime.utc(
      toDate.year,
      toDate.month,
      toDate.day,
    ).add(const Duration(days: 1));
    return ReportPeriod._(
      preset: ReportPeriodPreset.custom,
      from: fromNpt.subtract(nptOffset),
      to: toNptExclusive.subtract(nptOffset),
    );
  }

  factory ReportPeriod.fromQuery(String? period, {DateTime? now}) {
    return switch (period) {
      'today' => ReportPeriod.preset(ReportPeriodPreset.today, now: now),
      '7d' || 'last7Days' => ReportPeriod.preset(
        ReportPeriodPreset.last7Days,
        now: now,
      ),
      '30d' || 'last30Days' => ReportPeriod.preset(
        ReportPeriodPreset.last30Days,
        now: now,
      ),
      'month' || 'thisMonth' => ReportPeriod.preset(
        ReportPeriodPreset.thisMonth,
        now: now,
      ),
      'bsMonth' => ReportPeriod.preset(
        ReportPeriodPreset.bsThisMonth,
        now: now,
      ),
      'bsLastMonth' => ReportPeriod.preset(
        ReportPeriodPreset.bsLastMonth,
        now: now,
      ),
      'bsFy' => ReportPeriod.preset(ReportPeriodPreset.bsFiscalYear, now: now),
      'bsLastFy' => ReportPeriod.preset(
        ReportPeriodPreset.bsLastFiscalYear,
        now: now,
      ),
      _ => ReportPeriod.preset(ReportPeriodPreset.last7Days, now: now),
    };
  }

  String get queryValue => switch (preset) {
    ReportPeriodPreset.today => 'today',
    ReportPeriodPreset.last7Days => '7d',
    ReportPeriodPreset.last30Days => '30d',
    ReportPeriodPreset.thisMonth => 'month',
    ReportPeriodPreset.bsThisMonth => 'bsMonth',
    ReportPeriodPreset.bsLastMonth => 'bsLastMonth',
    ReportPeriodPreset.bsFiscalYear => 'bsFy',
    ReportPeriodPreset.bsLastFiscalYear => 'bsLastFy',
    ReportPeriodPreset.custom => 'custom',
  };

  /// Equal-length window immediately before this period (for trend %).
  ReportPeriod get previousEqualLength {
    final duration = to.difference(from);
    return ReportPeriod._(
      preset: ReportPeriodPreset.custom,
      from: from.subtract(duration),
      to: from,
    );
  }

  ReportDateRange get dateRange => ReportDateRange(from: from, to: to);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ReportPeriod &&
            other.preset == preset &&
            other.from == from &&
            other.to == to;
  }

  @override
  int get hashCode => Object.hash(preset, from, to);
}

/// Query key for bills-in-range provider (period + optional search).
class BillsRangeQuery {
  const BillsRangeQuery({required this.period, this.query = ''});

  final ReportPeriod period;
  final String query;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is BillsRangeQuery &&
            other.period == period &&
            other.query == query;
  }

  @override
  int get hashCode => Object.hash(period, query);
}
