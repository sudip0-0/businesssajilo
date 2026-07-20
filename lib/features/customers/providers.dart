import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/pagination.dart';
import '../../data/repositories/customers_repository.dart';
import '../../data/repositories/payments_repository.dart';
import '../../domain/models/customer.dart';
import '../../domain/models/ledger_entry.dart';

/// Bumped after customer writes so paginated customer lists can refresh.
final customersRevisionProvider =
    NotifierProvider<CustomersRevision, int>(CustomersRevision.new);

class CustomersRevision extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

void bumpCustomersRevision(WidgetRef ref) {
  ref.read(customersRevisionProvider.notifier).bump();
}

/// Bridge for callers that only have [Ref] (e.g. invalidate helpers).
void bumpCustomersRevisionFromRef(Ref ref) {
  ref.read(customersRevisionProvider.notifier).bump();
}

/// Capped customer list for pickers / autocomplete. Pass [query] for search.
final customerListProvider = FutureProvider.autoDispose
    .family<List<Customer>, String>((ref, query) {
      return ref
          .watch(customersRepositoryProvider)
          .list(
            limit: kPickerPageSize,
            query: query.trim().isEmpty ? null : query,
          );
    });

final recentCustomersProvider = FutureProvider.autoDispose<List<Customer>>((
  ref,
) {
  return ref.watch(customersRepositoryProvider).listRecent(limit: 2);
});

final customerDetailProvider = FutureProvider.autoDispose
    .family<Customer, String>((ref, id) {
      return ref.watch(customersRepositoryProvider).get(id);
    });

final customerLedgerProvider = FutureProvider.autoDispose
    .family<List<LedgerEntry>, String>((ref, id) {
      return ref.watch(customersRepositoryProvider).ledger(id);
    });

final ownCustomerProvider = FutureProvider.autoDispose<Customer?>((ref) {
  return ref.watch(customersRepositoryProvider).getOwnProfile();
});

final ownLedgerProvider = FutureProvider.autoDispose<List<LedgerEntry>>((
  ref,
) async {
  final customer = await ref.watch(ownCustomerProvider.future);
  if (customer == null) return [];
  return ref.watch(customersRepositoryProvider).ledger(customer.id);
});

final totalDuesProvider = FutureProvider.autoDispose<int>((ref) {
  return ref.watch(paymentsRepositoryProvider).totalDues();
});
