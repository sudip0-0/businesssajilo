import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../customers/providers.dart';
import '../inventory/providers.dart';
import '../orders/providers.dart';
import '../reports/dashboard/dashboard_invalidation.dart';
import 'credit_note_providers.dart';
import 'providers.dart';

/// Bridge for Riverpod 3: [WidgetRef] is not a [Ref].
///
/// Widgets call `ref.read(billingRefProvider)` when invoking Ref-based helpers.
final billingRefProvider = Provider<Ref>((ref) => ref);

/// Invalidates list/dashboard/customer/order/credit-note providers after writes.
void invalidateAfterBillSaved(
  Ref ref, {
  String? customerId,
  String? orderId,
  String? billId,
}) {
  ref.invalidate(billListProvider);
  ref.invalidate(todaysSalesProvider);
  ref.invalidate(pendingTodaysSalesProvider);
  ref.invalidate(todaysBillCountProvider);
  ref.invalidate(todaysBillsProvider);
  ref.invalidate(totalDuesProvider);
  invalidateOwnerDashboard(ref);
  bumpBillingRevisionFromRef(ref);
  bumpCustomersRevisionFromRef(ref);
  bumpInventoryRevisionFromRef(ref);
  ref.invalidate(productListProvider);
  ref.invalidate(lowStockCountProvider);
  ref.invalidate(lowStockAlertsProvider);
  ref.invalidate(lowStockProductsProvider);
  if (customerId != null) {
    ref.invalidate(customerListProvider);
    ref.invalidate(customerDetailProvider(customerId));
    ref.invalidate(customerLedgerProvider(customerId));
  }
  if (orderId != null) {
    ref.invalidate(orderDetailProvider(orderId));
    ref.invalidate(orderQueueProvider);
    ref.invalidate(staffOrderListProvider);
    ref.invalidate(ownOrderListProvider);
    ref.invalidate(pendingOrdersCountProvider);
  }
  if (billId != null) {
    ref.invalidate(billDetailProvider(billId));
    ref.invalidate(billReturnedQtyProvider(billId));
  }
}

/// Invalidates customer ledger caches after a standalone payment.
void invalidateAfterCustomerPayment(Ref ref, {required String customerId}) {
  ref.invalidate(customerDetailProvider(customerId));
  ref.invalidate(customerLedgerProvider(customerId));
  ref.invalidate(customerListProvider);
  ref.invalidate(totalDuesProvider);
  invalidateOwnerDashboard(ref);
  bumpCustomersRevisionFromRef(ref);
  bumpBillingRevisionFromRef(ref);
}

/// Invalidates bill + ledger caches after a credit note is created.
void invalidateAfterCreditNoteSaved(
  Ref ref, {
  required String billId,
  String? customerId,
}) {
  ref.invalidate(billDetailProvider(billId));
  ref.invalidate(billReturnedQtyProvider(billId));
  ref.invalidate(billListProvider);
  invalidateOwnerDashboard(ref);
  bumpBillingRevisionFromRef(ref);
  bumpInventoryRevisionFromRef(ref);
  bumpCustomersRevisionFromRef(ref);
  ref.invalidate(productListProvider);
  ref.invalidate(lowStockCountProvider);
  ref.invalidate(lowStockAlertsProvider);
  ref.invalidate(lowStockProductsProvider);
  if (customerId != null) {
    ref.invalidate(customerLedgerProvider(customerId));
    ref.invalidate(customerDetailProvider(customerId));
    ref.invalidate(customerListProvider);
    ref.invalidate(totalDuesProvider);
  }
}
