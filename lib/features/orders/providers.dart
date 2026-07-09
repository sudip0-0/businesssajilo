import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/orders_repository.dart';
import '../../domain/enums.dart';
import '../../domain/models/order.dart';

final staffOrderListProvider = FutureProvider.autoDispose<List<Order>>((ref) {
  return ref.watch(ordersRepositoryProvider).listForStaff();
});

final ownOrderListProvider = FutureProvider.autoDispose<List<Order>>((ref) {
  return ref.watch(ordersRepositoryProvider).listOwn();
});

final orderDetailProvider = FutureProvider.autoDispose.family<Order, String>((
  ref,
  id,
) {
  return ref.watch(ordersRepositoryProvider).get(id);
});

final pendingOrdersCountProvider = FutureProvider.autoDispose<int>((ref) {
  return ref.watch(ordersRepositoryProvider).pendingCount();
});

final openQuotesCountProvider = FutureProvider.autoDispose<int>((ref) {
  return ref.watch(ordersRepositoryProvider).openQuotesCount();
});

final fulfillmentQueueProvider = FutureProvider.autoDispose<List<Order>>((ref) {
  return ref.watch(ordersRepositoryProvider).fulfillmentQueue();
});

final orderQueueProvider = FutureProvider.autoDispose<List<Order>>((ref) async {
  return ref
      .watch(ordersRepositoryProvider)
      .listForStaff(
        statuses: [
          OrderStatus.placed,
          OrderStatus.quoted,
          OrderStatus.accepted,
        ],
      );
});
