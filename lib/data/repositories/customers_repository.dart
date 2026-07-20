import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/ledger_balance.dart';
import '../../domain/enums.dart';
import '../../domain/models/customer.dart';
import '../../domain/models/ledger_entry.dart';
import '../remote/supabase_provider.dart';
import '../repositories/members_repository.dart';
import '../sync/cached_customers_repository.dart';
import '../sync/sync_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final customersRepositoryProvider = Provider<CustomersRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final bundle = ref.watch(syncBundleProvider);
  if (bundle != null) {
    return CachedCustomersRepository(
      db: bundle.db,
      client: client,
      sync: bundle.sync,
    );
  }
  return SupabaseCustomersRepository(client);
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
  });
}

class SupabaseCustomersRepository implements CustomersRepository {
  SupabaseCustomersRepository(this._client);

  final SupabaseClient? _client;

  @override
  Future<List<Customer>> list({
    int offset = 0,
    int? limit,
    String? query,
  }) async {
    final client = _requireClient();
    var filter = client.from('customer_balances').select();
    final q = query?.trim();
    if (q != null && q.isNotEmpty) {
      // Commas break PostgREST `or` filter syntax.
      final pattern = '%${q.replaceAll(',', '')}%';
      filter = filter.or(
        'shop_name.ilike.$pattern,contact_name.ilike.$pattern,phone.ilike.$pattern',
      );
    }
    var built = filter.order('shop_name', ascending: true);
    if (limit != null) {
      built = built.range(offset, offset + limit - 1);
    }
    final rows = await built;
    return (rows as List).map(_mapBalanceRow).toList();
  }

  @override
  Future<List<Customer>> listRecent({int limit = 2}) async {
    final client = _requireClient();
    final rows = await client
        .from('customer_balances')
        .select()
        .order('created_at', ascending: false)
        .range(0, limit - 1);
    return (rows as List).map(_mapBalanceRow).toList();
  }

  @override
  Future<Customer> get(String id) async {
    final client = _requireClient();
    final row = await client.from('customers').select().eq('id', id).single();
    final customer = _mapCustomerRow(row);
    final balanceRow = await client
        .from('customer_balances')
        .select('balance_due')
        .eq('customer_id', id)
        .maybeSingle();
    if (balanceRow != null) {
      return customer.copyWith(
        balanceDue: (balanceRow['balance_due'] as num?)?.toInt() ?? 0,
      );
    }
    return customer;
  }

  @override
  Future<Customer?> getOwnProfile() async {
    final client = _requireClient();
    final row = await client.from('customers').select().maybeSingle();
    if (row == null) return null;
    final customer = _mapCustomerRow(row);
    final balanceRow = await client
        .from('customer_balances')
        .select()
        .eq('customer_id', customer.id)
        .maybeSingle();
    if (balanceRow != null) return _mapBalanceRow(balanceRow);
    return customer;
  }

  @override
  Future<List<LedgerEntry>> ledger(
    String customerId, {
    int offset = 0,
    int? limit,
  }) async {
    final client = _requireClient();
    var query = client
        .from('customer_ledger_entries')
        .select()
        .eq('customer_id', customerId)
        .order('occurred_at', ascending: true)
        .order('entry_type', ascending: true)
        .order('ref_id', ascending: true);
    if (limit != null) {
      query = query.range(offset, offset + limit - 1);
    }
    final rows = await query;
    final entries = (rows as List)
        .map(
          (row) => LedgerEntry.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
    if (limit != null) return entries;
    return withRunningBalance(entries);
  }

  @override
  Future<Customer> update({
    required String id,
    required String shopName,
    String? contactName,
    String? phone,
    String? address,
    required int openingBalance,
  }) async {
    final client = _requireClient();
    await client
        .from('customers')
        .update({
          'shop_name': shopName,
          'contact_name': ?contactName,
          'phone': ?phone,
          'address': ?address,
          'opening_balance': openingBalance,
        })
        .eq('id', id);
    return get(id);
  }

  @override
  Future<Customer> createWithCredentials({
    String? email,
    required String password,
    required String displayName,
    required String shopName,
    String? contactName,
    String? phone,
    String? address,
    int openingBalance = 0,
  }) async {
    final membersRepo = MembersRepository(_client);
    final result = await membersRepo.createMember(
      email: email,
      password: password,
      role: Role.customer,
      displayName: displayName,
      phone: phone,
      shopName: shopName,
      contactName: contactName,
      address: address,
      openingBalance: openingBalance,
    );
    final customerId = result.customerId;
    if (customerId == null) {
      throw Exception('Customer was not created');
    }
    return get(customerId);
  }

  Customer _mapBalanceRow(dynamic row) {
    final map = Map<String, dynamic>.from(row as Map);
    return Customer(
      id: map['customer_id'] as String,
      businessId: map['business_id'] as String,
      memberId: map['member_id'] as String? ?? '',
      shopName: map['shop_name'] as String,
      contactName: map['contact_name'] as String?,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      openingBalance: (map['opening_balance'] as num?)?.toInt() ?? 0,
      balanceDue: (map['balance_due'] as num?)?.toInt() ?? 0,
      createdAt: map['created_at'] == null
          ? null
          : DateTime.parse(map['created_at'] as String),
    );
  }

  Customer _mapCustomerRow(dynamic row) {
    final map = Map<String, dynamic>.from(row as Map);
    return Customer.fromJson(map);
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) throw Exception('Supabase not configured');
    return client;
  }
}
