import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/ui/error_state.dart';
import '../../../../domain/models/owner_dashboard_stats.dart';
import '../../../../features/reports/dashboard/dashboard_kpi_format.dart';
import '../../../layout/web_bento_grid.dart';
import '../../../ui/web_stat_tile.dart';

/// Owner dashboard KPI bento grid (web).
class WebDashboardKpiGrid extends StatelessWidget {
  const WebDashboardKpiGrid({
    super.key,
    required this.stats,
    required this.onRetry,
  });

  final AsyncValue<OwnerDashboardStats> stats;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (stats.hasError && !stats.hasValue) {
      return SizedBox(
        height: 120,
        child: ErrorState(message: l10n.loadingFailed, onRetry: onRetry),
      );
    }

    return WebBentoGrid(
      children: [
        WebStatTile(
          label: l10n.todaysSales,
          value: stats.when(
            data: (d) => formatDashboardKpiAmount(l10n, d.todaySales),
            loading: () => '…',
            error: (_, _) => l10n.loadingFailed,
          ),
          icon: PhosphorIconsRegular.currencyDollar,
          trend: stats.when(
            data: (d) {
              final pct = d.salesTrendPercent;
              if (pct == null) return null;
              return pct >= 0 ? WebTrendDirection.up : WebTrendDirection.down;
            },
            loading: () => null,
            error: (_, _) => null,
          ),
          trendLabel: stats.when(
            data: (d) => formatDashboardTrendPercent(d),
            loading: () => null,
            error: (_, _) => null,
          ),
          onTap: () => context.go('/owner/reports/sales'),
        ),
        WebStatTile(
          label: l10n.totalDues,
          value: stats.when(
            data: (d) => formatDashboardKpiAmount(l10n, d.totalDues),
            loading: () => '…',
            error: (_, _) => l10n.loadingFailed,
          ),
          icon: PhosphorIconsRegular.wallet,
          onTap: () => context.go('/owner/reports/dues'),
        ),
        WebStatTile(
          label: l10n.lowStock,
          value: stats.when(
            data: (d) {
              final count = d.lowStockCount;
              if (count == null) return l10n.valueUnavailable;
              return '$count ${l10n.products.toLowerCase()}';
            },
            loading: () => '…',
            error: (_, _) => l10n.loadingFailed,
          ),
          icon: PhosphorIconsRegular.package,
          subtitle: stats.when(
            data: (d) => (d.lowStockCount ?? 0) > 0 ? l10n.reorderSoon : null,
            loading: () => null,
            error: (_, _) => null,
          ),
          onTap: () => context.go('/owner/reports/stock'),
        ),
        WebStatTile(
          label: l10n.pendingOrders,
          value: stats.when(
            data: (d) {
              final count = d.pendingOrders;
              if (count == null) return l10n.valueUnavailable;
              return '$count ${l10n.orders.toLowerCase()}';
            },
            loading: () => '…',
            error: (_, _) => l10n.loadingFailed,
          ),
          icon: PhosphorIconsRegular.shoppingCart,
          trendLabel: stats.when(
            data: (d) =>
                (d.pendingOrders ?? 0) > 0 ? '${d.pendingOrders} NEW' : null,
            loading: () => null,
            error: (_, _) => null,
          ),
          trend: stats.when(
            data: (d) => (d.pendingOrders ?? 0) > 0
                ? WebTrendDirection.neutral
                : null,
            loading: () => null,
            error: (_, _) => null,
          ),
          onTap: () => context.go('/owner/orders'),
        ),
      ],
    );
  }
}
