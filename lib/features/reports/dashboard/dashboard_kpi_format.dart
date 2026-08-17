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

String? formatPendingSyncSalesSubtitle(
  AppLocalizations l10n,
  int pendingPaisa,
) {
  if (pendingPaisa <= 0) return null;
  return l10n.pendingSyncSalesHint(
    formatNpr(Paisa(pendingPaisa), showPaisa: false),
  );
}

/// Trend percent label for sales KPI (null when unavailable or no sales today).
String? formatDashboardTrendPercent(OwnerDashboardStats stats) {
  if (stats.todaySales == 0) return null;
  final pct = stats.salesTrendPercent;
  if (pct == null) return null;
  return '${pct.abs().toStringAsFixed(0)}%';
}
