import '../../core/utils/ledger_balance.dart';
import '../../domain/enums.dart';
import '../../domain/models/customer.dart';
import '../../domain/models/ledger_entry.dart';
import '../local/app_database.dart';
import '../local/local_mappers.dart';
import '../repositories/customers_repository.dart';
import '../repositories/members_repository.dart';
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CachedCustomersRepository implements CustomersRepository {
  CachedCustomersRepository({
    required AppDatabase db,
    required SupabaseClient? client,
  }) : _db = db,
       _client = client;

  final AppDatabase _db;
  final SupabaseClient? _client;

  @override
  Future<List<Customer>> list({
    int offset = 0,
    int? limit,
    String? query,
  }) async {
    final q = query?.trim();
    if (q != null && q.isNotEmpty) {
      final pattern = '%${q.toLowerCase()}%';
      final rows = await _db
          .customSelect(
            'SELECT * FROM local_customers '
            'WHERE lower(shop_name) LIKE ? '
            'OR lower(ifnull(contact_name, \'\')) LIKE ? '
            'OR ifnull(phone, \'\') LIKE ? '
            'ORDER BY shop_name ASC '
            'LIMIT ? OFFSET ?',
            variables: [
              Variable.withString(pattern),
              Variable.withString(pattern),
              Variable.withString(pattern),
              Variable.withInt(limit ?? 50),
              Variable.withInt(offset),
            ],
            readsFrom: {_db.localCustomers},
          )
          .map((row) => _db.localCustomers.map(row.data))
          .get();
      return rows.map(mapLocalCustomer).toList();
    }
    final select = _db.select(_db.localCustomers)
      ..orderBy([(c) => OrderingTerm.asc(c.shopName)]);
    if (limit != null) {
      select.limit(limit, offset: offset);
    }
    final rows = await select.get();
    return rows.map(mapLocalCustomer).toList();
  }

  @override
  Future<List<Customer>> listRecent({int limit = 2}) async {
    final rows =
        await (_db.select(_db.localCustomers)
              ..orderBy([
                (c) => OrderingTerm.desc(c.createdAt),
                (c) => OrderingTerm.asc(c.shopName),
              ])
              ..limit(limit))
            .get();
    return rows.map(mapLocalCustomer).toList();
  }

  @override
  Future<Customer> get(String id) async {
    final row = await (_db.select(
      _db.localCustomers,
    )..where((c) => c.id.equals(id))).getSingle();
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
    final client = _client;
    if (client == null) throw Exception('Supabase not configured');
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
}
