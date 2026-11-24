import '../../core/preferences/saved_filters_store.dart';
import '../../core/utils/report_range.dart';
import '../reports/report_period.dart';

/// Encodes a [ReportPeriod] into [BillListFilterState] fields.
({String? periodQuery, int? customFromMs, int? customToMs}) encodeBillPeriod(
  ReportPeriod? period,
) {
  if (period == null) {
    return (periodQuery: null, customFromMs: null, customToMs: null);
  }
  if (period.preset == ReportPeriodPreset.custom) {
    final fromNpt = period.from.add(nptOffset);
    final toInclusiveNpt = period.to
        .add(nptOffset)
        .subtract(const Duration(days: 1));
    return (
      periodQuery: 'custom',
      customFromMs: DateTime.utc(
        fromNpt.year,
        fromNpt.month,
        fromNpt.day,
      ).millisecondsSinceEpoch,
      customToMs: DateTime.utc(
        toInclusiveNpt.year,
        toInclusiveNpt.month,
        toInclusiveNpt.day,
      ).millisecondsSinceEpoch,
    );
  }
  return (periodQuery: period.queryValue, customFromMs: null, customToMs: null);
}

/// Restores a [ReportPeriod] from [BillListFilterState].
ReportPeriod? decodeBillPeriod(BillListFilterState state) {
  final query = state.periodQuery;
  if (query == null || query.isEmpty) return null;
  if (query == 'custom') {
    final fromMs = state.customFromMs;
    final toMs = state.customToMs;
    if (fromMs == null || toMs == null) return null;
    final fromDate = DateTime.fromMillisecondsSinceEpoch(fromMs, isUtc: true);
    final toDate = DateTime.fromMillisecondsSinceEpoch(toMs, isUtc: true);
    return ReportPeriod.custom(fromDate: fromDate, toDate: toDate);
  }
  return ReportPeriod.fromQuery(query);
}
