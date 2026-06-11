import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/customers_repository.dart';
import '../../data/repositories/payments_repository.dart';
import '../../domain/models/customer.dart';
import '../../domain/models/ledger_entry.dart';

final customerListProvider = FutureProvider.autoDispose<List<Customer>>((ref) {
  return ref.watch(customersRepositoryProvider).list();
});

final customerDetailProvider =
    FutureProvider.autoDispose.family<Customer, String>((ref, id) {
  return ref.watch(customersRepositoryProvider).get(id);
});

final customerLedgerProvider =
    FutureProvider.autoDispose.family<List<LedgerEntry>, String>((ref, id) {
  return ref.watch(customersRepositoryProvider).ledger(id);
});

final ownCustomerProvider = FutureProvider.autoDispose<Customer?>((ref) {
  return ref.watch(customersRepositoryProvider).getOwnProfile();
});

final ownLedgerProvider = FutureProvider.autoDispose<List<LedgerEntry>>((ref) async {
  final customer = await ref.watch(ownCustomerProvider.future);
  if (customer == null) return [];
  return ref.watch(customersRepositoryProvider).ledger(customer.id);
});

final totalDuesProvider = FutureProvider.autoDispose<int>((ref) {
  return ref.watch(paymentsRepositoryProvider).totalDues();
});
