import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/bills_repository.dart';
import '../../domain/models/bill.dart';

final billListProvider = FutureProvider.autoDispose<List<Bill>>((ref) {
  return ref.watch(billsRepositoryProvider).list();
});

final billDetailProvider =
    FutureProvider.autoDispose.family<Bill, String>((ref, id) {
  return ref.watch(billsRepositoryProvider).get(id);
});

final todaysSalesProvider = FutureProvider.autoDispose<int>((ref) {
  return ref.watch(billsRepositoryProvider).todaysSales();
});

final todaysBillCountProvider = FutureProvider.autoDispose<int>((ref) {
  return ref.watch(billsRepositoryProvider).todaysBillCount();
});
