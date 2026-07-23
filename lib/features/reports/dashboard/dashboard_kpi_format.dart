import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/money.dart';
import '../../../domain/models/owner_dashboard_stats.dart';

/// Formats a KPI amount in NPR, or [valueUnavailable] when null.
String formatDashboardKpiAmount(
  AppLocalizations l10n,
  int? paisa, {
  bool showUnavailableOnNull = true,
}) {
  if (paisa == null) {
    return showUnavailableOnNull ? l10n.valueUnavailable : l10n.loadingFailed;
  }
  return formatNpr(Paisa(paisa), showPaisa: false);
}

/// Formats a KPI count, or [valueUnavailable] when null.
String formatDashboardKpiCount(AppLocalizations l10n, int? count) {
  if (count == null) return l10n.valueUnavailable;
  return '$count';
}

/// Trend percent label for sales KPI (null when unavailable).
String? formatDashboardTrendPercent(OwnerDashboardStats stats) {
  final pct = stats.salesTrendPercent;
  if (pct == null) return null;
  return '${pct.abs().toStringAsFixed(0)}%';
}
