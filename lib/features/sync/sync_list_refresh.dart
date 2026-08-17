import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/sync/sync_providers.dart';
import '../billing/providers.dart';
import '../customers/providers.dart';
import '../inventory/providers.dart';
import '../orders/providers.dart';
import '../reports/dashboard/dashboard_invalidation.dart';

/// Always-on: when the local sync queue changes, bump list revisions so
/// IndexedStack pagers (bills, products, customers, orders) reload without
/// a manual pull-to-refresh.
final syncQueueListRefreshProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<SyncStatus>>(syncStatusProvider, (prev, next) {
    if (prev == null) return;
    // Skip the initial AsyncLoading → first value so lists don't reload
    // on app start.
    if (prev.value == null) return;
    if (prev.value?.refreshEpoch == next.value?.refreshEpoch) return;
    ref.read(billingRevisionProvider.notifier).bump();
    ref.read(inventoryRevisionProvider.notifier).bump();
    ref.read(customersRevisionProvider.notifier).bump();
    ref.invalidate(billListProvider);
    ref.invalidate(billDetailProvider);
    ref.invalidate(todaysBillsProvider);
    ref.invalidate(todaysBillCountProvider);
    ref.invalidate(productListProvider);
    ref.invalidate(productDetailProvider);
    ref.invalidate(lowStockCountProvider);
    ref.invalidate(lowStockAlertsProvider);
    ref.invalidate(lowStockProductsProvider);
    ref.invalidate(staffOrderListProvider);
    ref.invalidate(ownOrderListProvider);
    ref.invalidate(orderQueueProvider);
    ref.invalidate(pendingOrdersCountProvider);
    ref.invalidate(orderDetailProvider);
    invalidateOwnerDashboard(ref);
  });
});
