import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/bills_repository.dart';
import '../../domain/models/bill.dart';

/// Bumped after bill/payment writes so paginated bill lists can refresh.
final billingRevisionProvider =
    NotifierProvider<BillingRevision, int>(BillingRevision.new);

class BillingRevision extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

void bumpBillingRevision(WidgetRef ref) {
  ref.read(billingRevisionProvider.notifier).bump();
}

/// Bridge for callers that only have [Ref] (e.g. save helpers).
void bumpBillingRevisionFromRef(Ref ref) {
  ref.read(billingRevisionProvider.notifier).bump();
}

final billListProvider = FutureProvider.autoDispose<List<Bill>>((ref) {
  return ref.watch(billsRepositoryProvider).list();
});

final billDetailProvider = FutureProvider.autoDispose.family<Bill, String>((
  ref,
  id,
) {
  return ref.watch(billsRepositoryProvider).get(id);
});

final todaysSalesProvider = FutureProvider.autoDispose<int>((ref) {
  return ref.watch(billsRepositoryProvider).todaysSales();
});

final todaysBillCountProvider = FutureProvider.autoDispose<int>((ref) {
  return ref.watch(billsRepositoryProvider).todaysBillCount();
});

final yesterdaysSalesProvider = FutureProvider.autoDispose<int>((ref) {
  return ref.watch(billsRepositoryProvider).yesterdaysSales();
});

final todaysBillsProvider = FutureProvider.autoDispose<List<Bill>>((ref) {
  return ref.watch(billsRepositoryProvider).listTodaysBills(limit: 20);
});

/// Percent change in today's sales vs yesterday (null when no baseline).
final salesTrendProvider = FutureProvider.autoDispose<double?>((ref) async {
  final today = await ref.watch(todaysSalesProvider.future);
  final yesterday = await ref.watch(yesterdaysSalesProvider.future);
  if (yesterday == 0) return today > 0 ? 100.0 : null;
  return ((today - yesterday) / yesterday) * 100;
});
