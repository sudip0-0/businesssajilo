import '../../core/utils/ledger_balance.dart';
import '../../domain/enums.dart';
import '../../domain/models/customer.dart';
import '../../domain/models/ledger_entry.dart';
import '../local/app_database.dart';
import '../local/local_mappers.dart';
import '../repositories/customers_repository.dart';
import '../repositories/members_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CachedCustomersRepository implements CustomersRepository {
  CachedCustomersRepository({
    required AppDatabase db,
    required SupabaseClient? client,
  })  : _db = db,
        _client = client;

  final AppDatabase _db;
  final SupabaseClient? _client;

  @override
  Future<List<Customer>> list({int offset = 0, int? limit}) async {
    final rows = await _db.select(_db.localCustomers).get();
    rows.sort((a, b) => a.shopName.compareTo(b.shopName));
    final mapped = rows.map(mapLocalCustomer).toList();
    if (limit == null) return mapped;
    return mapped.skip(offset).take(limit).toList();
  }

  @override
  Future<Customer> get(String id) async {
    final row = await (_db.select(_db.localCustomers)
          ..where((c) => c.id.equals(id)))
        .getSingle();
    return mapLocalCustomer(row);
  }

  @override
  Future<Customer?> getOwnProfile() async {
    final client = _client;
    if (client == null) return null;
    final row = await client.from('customers').select().maybeSingle();
    if (row == null) return null;
    return Customer.fromJson(Map<String, dynamic>.from(row));
  }

  @override
  Future<List<LedgerEntry>> ledger(
    String customerId, {
    int offset = 0,
    int? limit,
  }) async {
    final client = _client;
    if (client == null) throw Exception('Supabase not configured');
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
        .map((row) => LedgerEntry.fromJson(Map<String, dynamic>.from(row as Map)))
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
    final client = _client;
    if (client == null) throw Exception('Supabase not configured');
    await client.from('customers').update({
      'shop_name': shopName,
      'contact_name': ?contactName,
      'phone': ?phone,
      'address': ?address,
      'opening_balance': openingBalance,
    }).eq('id', id);
    return get(id);
  }

  @override
  Future<Customer> createWithCredentials({
    required String email,
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
}
