import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/customer.dart';
import '../../domain/models/ledger_entry.dart';
import '../remote/supabase_customers_repository.dart';
import '../remote/supabase_provider.dart';
import '../sync/cached_customers_repository.dart';
import '../sync/sync_providers.dart';

final customersRepositoryProvider = Provider<CustomersRepository>((ref) {
  final remote = SupabaseCustomersRepository(ref.watch(supabaseClientProvider));
  final bundle = ref.watch(syncBundleProvider);
  if (bundle != null) {
    return CachedCustomersRepository(
      db: bundle.db,
      remote: remote,
      sync: bundle.sync,
    );
  }
  return remote;
});

abstract class CustomersRepository {
  Future<List<Customer>> list({int offset = 0, int? limit, String? query});

  /// Most recently created customers, capped for dashboards.
  Future<List<Customer>> listRecent({int limit = 2});
  Future<Customer> get(String id);
  Future<Customer?> getOwnProfile();

  /// Returns ledger entries sorted ascending by occurred_at. When [limit] is
  /// given, returns a page starting at [offset]; entries are raw (no running
  /// balance) so callers can accumulate pages and apply [withRunningBalance].
  Future<List<LedgerEntry>> ledger(
    String customerId, {
    int offset = 0,
    int? limit,
  });
  Future<Customer> update({
    required String id,
    required String shopName,
    String? contactName,
    String? phone,
    String? address,
    required int openingBalance,
  });
  Future<Customer> createWithCredentials({
    String? email,
    required String password,
    required String displayName,
    required String shopName,
    String? contactName,
    String? phone,
    String? address,
    int openingBalance,
    bool portalEnabled = true,
  });
}
