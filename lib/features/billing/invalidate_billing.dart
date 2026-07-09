import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../customers/providers.dart';
import '../orders/providers.dart';
import '../reports/providers.dart';
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
  ref.invalidate(todaysBillCountProvider);
  ref.invalidate(todaysBillsProvider);
  ref.invalidate(totalDuesProvider);
  ref.invalidate(ownerDashboardStatsProvider);
  if (customerId != null) {
    ref.invalidate(customerListProvider);
    ref.invalidate(customerDetailProvider(customerId));
    ref.invalidate(customerLedgerProvider(customerId));
  }
  if (orderId != null) {
    ref.invalidate(orderDetailProvider(orderId));
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
  ref.invalidate(ownerDashboardStatsProvider);
}

/// Invalidates bill + ledger caches after a credit note is created.
void invalidateAfterCreditNoteSaved(
  Ref ref, {
  required String billId,
  String? customerId,
}) {
  ref.invalidate(billDetailProvider(billId));
  ref.invalidate(billReturnedQtyProvider(billId));
  ref.invalidate(ownerDashboardStatsProvider);
  if (customerId != null) {
    ref.invalidate(customerLedgerProvider(customerId));
    ref.invalidate(totalDuesProvider);
  }
}
