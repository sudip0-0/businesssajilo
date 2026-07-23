import 'dart:async';

import 'package:drift/drift.dart';

import '../../domain/models/customer.dart';
import '../../domain/models/ledger_entry.dart';
import '../local/app_database.dart';
import '../local/local_mappers.dart';
import '../remote/supabase_customers_repository.dart';
import '../repositories/customers_repository.dart';
import 'sync_service.dart';

class CachedCustomersRepository implements CustomersRepository {
  CachedCustomersRepository({
    required AppDatabase db,
    required SupabaseCustomersRepository remote,
    SyncService? sync,
  }) : _db = db,
       _remote = remote,
       _sync = sync;

  final AppDatabase _db;
  final SupabaseCustomersRepository _remote;
  final SyncService? _sync;

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
  Future<Customer?> getOwnProfile() => _remote.getOwnProfile();

  @override
  Future<List<LedgerEntry>> ledger(
    String customerId, {
    int offset = 0,
    int? limit,
  }) => _remote.ledger(customerId, offset: offset, limit: limit);

  @override
  Future<Customer> update({
    required String id,
    required String shopName,
    String? contactName,
    String? phone,
    String? address,
    required int openingBalance,
  }) async {
    await _remote.update(
      id: id,
      shopName: shopName,
      contactName: contactName,
      phone: phone,
      address: address,
      openingBalance: openingBalance,
    );
    final updated = await _remote.getBalanceRow(id);
    await _upsertLocal(updated);
    final sync = _sync;
    if (sync != null) unawaited(sync.syncNow());
    return updated;
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
    bool portalEnabled = true,
  }) async {
    final created = await _remote.createWithCredentials(
      email: email,
      password: password,
      displayName: displayName,
      shopName: shopName,
      contactName: contactName,
      phone: phone,
      address: address,
      openingBalance: openingBalance,
      portalEnabled: portalEnabled,
    );
    final customer = await _remote.getBalanceRow(created.id);
    await _upsertLocal(customer);
    final sync = _sync;
    if (sync != null) unawaited(sync.syncNow());
    return customer;
  }

  Future<void> _upsertLocal(Customer customer) async {
    final now = DateTime.now().toUtc();
    await _db
        .into(_db.localCustomers)
        .insertOnConflictUpdate(
          LocalCustomersCompanion.insert(
            id: customer.id,
            businessId: customer.businessId,
            memberId: customer.memberId,
            shopName: customer.shopName,
            contactName: Value(customer.contactName),
            phone: Value(customer.phone),
            address: Value(customer.address),
            openingBalance: Value(customer.openingBalance),
            balanceDue: Value(customer.balanceDue),
            updatedAt: now,
            createdAt: Value(customer.createdAt),
          ),
        );
  }
}
