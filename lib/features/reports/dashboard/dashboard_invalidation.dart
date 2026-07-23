import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/enums.dart';
import '../../billing/providers.dart';
import '../../customers/providers.dart';
import '../../inventory/providers.dart';
import '../../orders/providers.dart';
import '../providers.dart';

void _invalidateOwnerDashboardCore(dynamic ref) {
  ref.invalidate(last7DaySalesProvider);
  ref.invalidate(salesDailyProvider(ReportRange.last30Days));
  ref.invalidate(salesDailyProvider(ReportRange.last7Days));
  ref.invalidate(ownerDashboardStatsProvider);
  ref.invalidate(lowStockAlertsProvider);
  ref.invalidate(todaysBillsProvider);
  ref.invalidate(recentCustomersProvider);
}

/// Invalidates all owner-dashboard data sources (Ref context, e.g. repositories).
void invalidateOwnerDashboard(Ref ref) => _invalidateOwnerDashboardCore(ref);

/// Widget-layer alias when only [WidgetRef] is in scope.
void invalidateOwnerDashboardWidget(WidgetRef ref) =>
    _invalidateOwnerDashboardCore(ref);

void _invalidateSalesDashboardCore(dynamic ref) {
  ref.invalidate(pendingOrdersCountProvider);
  ref.invalidate(openQuotesCountProvider);
  ref.invalidate(todaysBillCountProvider);
  ref.invalidate(todaysSalesProvider);
  ref.invalidate(totalDuesProvider);
}

void invalidateSalesDashboard(Ref ref) => _invalidateSalesDashboardCore(ref);

void invalidateSalesDashboardWidget(WidgetRef ref) =>
    _invalidateSalesDashboardCore(ref);

void _invalidateCustomerDashboardCore(dynamic ref) {
  ref.invalidate(ownOrderCountProvider);
  ref.invalidate(totalDuesProvider);
}

void invalidateCustomerDashboard(Ref ref) => _invalidateCustomerDashboardCore(ref);

void invalidateCustomerDashboardWidget(WidgetRef ref) =>
    _invalidateCustomerDashboardCore(ref);
