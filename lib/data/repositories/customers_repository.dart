import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/ledger_balance.dart';
import '../../domain/enums.dart';
import '../../domain/models/customer.dart';
import '../../domain/models/ledger_entry.dart';
import '../remote/supabase_provider.dart';
import 'members_repository.dart';

final customersRepositoryProvider = Provider<CustomersRepository>((ref) {
  return CustomersRepository(ref.watch(supabaseClientProvider));
});

class CustomersRepository {
  CustomersRepository(this._client);

  final SupabaseClient? _client;

  Future<List<Customer>> list() async {
    final client = _requireClient();
    final rows = await client
        .from('customer_balances')
        .select()
        .order('shop_name', ascending: true);
    return (rows as List).map(_mapBalanceRow).toList();
  }

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

  Future<List<LedgerEntry>> ledger(String customerId) async {
    final client = _requireClient();
    final rows = await client
        .from('customer_ledger_entries')
        .select()
        .eq('customer_id', customerId)
        .order('occurred_at', ascending: true);
    final entries = (rows as List)
        .map((row) => LedgerEntry.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
    return withRunningBalance(entries);
  }

  Future<Customer> update({
    required String id,
    required String shopName,
    String? contactName,
    String? phone,
    String? address,
    required int openingBalance,
  }) async {
    final client = _requireClient();
    await client.from('customers').update({
      'shop_name': shopName,
      'contact_name': ?contactName,
      'phone': ?phone,
      'address': ?address,
      'opening_balance': openingBalance,
    }).eq('id', id);
    return get(id);
  }

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
