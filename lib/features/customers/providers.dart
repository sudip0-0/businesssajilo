import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/pagination.dart';
import '../../data/repositories/customers_repository.dart';
import '../../data/repositories/members_repository.dart';
import '../../data/repositories/payments_repository.dart';
import '../../domain/enums.dart';
import '../../domain/models/customer.dart';
import '../../domain/models/ledger_entry.dart';
import '../../domain/models/member.dart';
import '../auth/providers/auth_provider.dart';

/// Bumped after customer writes so paginated customer lists can refresh.
final customersRevisionProvider = NotifierProvider<CustomersRevision, int>(
  CustomersRevision.new,
);

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
/// Warehouse (and anyone without [RolePermissions.canViewCustomerBalance])
/// loads the directory without balances.
final customerListProvider = FutureProvider.autoDispose
    .family<List<Customer>, String>((ref, query) {
      ref.watch(customersRevisionProvider);
      final role = ref.watch(authProvider).value?.member?.role;
      final includeBalances = role?.canViewCustomerBalance ?? false;
      return ref
          .watch(customersRepositoryProvider)
          .list(
            limit: kPickerPageSize,
            query: query.trim().isEmpty ? null : query,
            includeBalances: includeBalances,
          );
    });

final recentCustomersProvider = FutureProvider.autoDispose<List<Customer>>((
  ref,
) {
  ref.watch(customersRevisionProvider);
  return ref.watch(customersRepositoryProvider).listRecent(limit: 2);
});

final customerDetailProvider = FutureProvider.autoDispose
    .family<Customer, String>((ref, id) {
      ref.watch(customersRevisionProvider);
      final role = ref.watch(authProvider).value?.member?.role;
      final includeBalances = role?.canViewCustomerBalance ?? false;
      return ref
          .watch(customersRepositoryProvider)
          .get(id, includeBalances: includeBalances);
    });

final customerLedgerProvider = FutureProvider.autoDispose
    .family<List<LedgerEntry>, String>((ref, id) {
      ref.watch(customersRevisionProvider);
      return ref.watch(customersRepositoryProvider).ledger(id);
    });

final customerMemberProvider = FutureProvider.autoDispose
    .family<Member?, String>((ref, memberId) async {
      if (memberId.isEmpty) return null;
      return ref.watch(membersRepositoryProvider).getMember(memberId);
    });

final ownCustomerProvider = FutureProvider.autoDispose<Customer?>((ref) {
  ref.watch(customersRevisionProvider);
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
  ref.watch(authProvider.select((s) => s.value?.member?.id));
  ref.watch(customersRevisionProvider);
  final link = ref.keepAlive();
  final timer = Timer(const Duration(seconds: 45), link.close);
  ref.onDispose(timer.cancel);
  return ref.watch(paymentsRepositoryProvider).totalDues();
});
