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
