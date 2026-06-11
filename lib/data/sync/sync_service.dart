import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../local/app_database.dart';
import 'sync_merge.dart';

const _maxAttempts = 5;
const _uuid = Uuid();

class SyncService {
  SyncService({
    required AppDatabase db,
    required SupabaseClient client,
    Connectivity? connectivity,
  })  : _db = db,
        _client = client,
        _connectivity = connectivity ?? Connectivity();

  final AppDatabase _db;
  final SupabaseClient _client;
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _syncing = false;

  Future<void> init(String deviceId) async {
    await _db.ensureDeviceMeta(deviceId);
    _connectivitySub ??= _connectivity.onConnectivityChanged.listen((_) {
      unawaited(syncNow());
    });
    await syncNow();
  }

  void dispose() {
    unawaited(_connectivitySub?.cancel());
    _connectivitySub = null;
  }

  Future<bool> get isOnline async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  Future<void> syncNow() async {
    if (_syncing) return;
    if (!await isOnline) return;
    _syncing = true;
    try {
      await _pull();
      await _push();
      await _pull();
    } finally {
      _syncing = false;
    }
  }

  Future<void> _pull() async {
    final now = DateTime.now().toUtc();
    final hasWatermarks =
        await _db.select(_db.syncWatermarks).get().then((r) => r.isNotEmpty);

    if (!hasWatermarks) {
      await _bootstrap();
    } else {
      await _pullDelta();
    }

    await _db.setWatermark('_global', now);
  }

  Future<void> _bootstrap() async {
    final categories = await _client.from('categories').select();
    for (final row in categories as List) {
      await _upsertCategory(row as Map<String, dynamic>);
    }

    final products = await _client
        .from('products')
        .select('*, categories(name)');
    for (final row in products as List) {
      await _upsertProduct(row as Map<String, dynamic>);
    }

    final customers = await _client.from('customer_balances').select();
    for (final row in customers as List) {
      await _upsertCustomerBalance(row as Map<String, dynamic>);
    }

    final bills = await _client
        .from('bills')
        .select('*, customers(shop_name), bill_items(*)')
        .order('created_at', ascending: false);
    for (final row in bills as List) {
      await _upsertRemoteBill(row as Map<String, dynamic>);
    }

    final payments = await _client.from('payments').select();
    for (final row in payments as List) {
      await _upsertRemotePayment(row as Map<String, dynamic>, synced: true);
    }

    final movements = await _client
        .from('stock_movements')
        .select('*, members(display_name)');
    for (final row in movements as List) {
      await _upsertRemoteMovement(row as Map<String, dynamic>, synced: true);
    }

    final ts = DateTime.now().toUtc();
    for (final table in [
      'categories',
      'products',
      'customers',
      'bills',
      'payments',
      'stock_movements',
    ]) {
      await _db.setWatermark(table, ts);
    }
  }

  Future<void> _pullDelta() async {
    final catWatermark = await _db.watermark('categories');
    if (catWatermark != null) {
      final rows = await _client
          .from('categories')
          .select()
          .gt('updated_at', catWatermark.toIso8601String());
      for (final row in rows as List) {
        await _upsertCategory(row as Map<String, dynamic>);
      }
    }

    final prodWatermark = await _db.watermark('products');
    if (prodWatermark != null) {
      final rows = await _client
          .from('products')
          .select('*, categories(name)')
          .gt('updated_at', prodWatermark.toIso8601String());
      for (final row in rows as List) {
        await _upsertProduct(row as Map<String, dynamic>);
      }
    }

    final custWatermark = await _db.watermark('customers');
    if (custWatermark != null) {
      final rows = await _client
          .from('customer_balances')
          .select()
          .gt('updated_at', custWatermark.toIso8601String());
      for (final row in rows as List) {
        await _upsertCustomerBalance(row as Map<String, dynamic>);
      }
    }

    final billWatermark = await _db.watermark('bills');
    if (billWatermark != null) {
      final rows = await _client
          .from('bills')
          .select('*, customers(shop_name), bill_items(*)')
          .gt('created_at', billWatermark.toIso8601String());
      for (final row in rows as List) {
        await _upsertRemoteBill(row as Map<String, dynamic>);
      }
    }

    final payWatermark = await _db.watermark('payments');
    if (payWatermark != null) {
      final rows = await _client
          .from('payments')
          .select()
          .gt('created_at', payWatermark.toIso8601String());
      for (final row in rows as List) {
        await _upsertRemotePayment(row as Map<String, dynamic>, synced: true);
      }
    }

    final movWatermark = await _db.watermark('stock_movements');
    if (movWatermark != null) {
      final rows = await _client
          .from('stock_movements')
          .select('*, members(display_name)')
          .gt('created_at', movWatermark.toIso8601String());
      for (final row in rows as List) {
        await _upsertRemoteMovement(row as Map<String, dynamic>, synced: true);
      }
    }

    final ts = DateTime.now().toUtc();
    for (final table in [
      'categories',
      'products',
      'customers',
      'bills',
      'payments',
      'stock_movements',
    ]) {
      await _db.setWatermark(table, ts);
    }
  }

  Future<void> _push() async {
    final queue = await _db.pendingQueue();
    final syncedIds = <String>{};

    for (final item in queue) {
      if (item.attempts >= _maxAttempts) continue;

      if (item.dependsOnId != null && !syncedIds.contains(item.dependsOnId)) {
        final parentPending = queue.any(
          (q) =>
              q.entityId == item.dependsOnId &&
              (q.status == 'pending' || q.status == 'failed'),
        );
        if (parentPending) continue;
      }

      try {
        final payload = jsonDecode(item.payloadJson) as Map<String, dynamic>;
        switch (item.entityType) {
          case 'bill':
            await _pushBill(payload);
            await _markBillSynced(item.entityId);
          case 'bill_items':
            await _pushBillItems(payload);
          case 'payment':
            await _pushPayment(payload);
            await _markPaymentSynced(item.entityId);
          case 'stock_movement':
            await _pushStockMovement(payload);
            await _markMovementSynced(item.entityId);
        }

        await (_db.update(_db.syncQueue)..where((q) => q.id.equals(item.id)))
            .write(const SyncQueueCompanion(status: Value('synced')));
        syncedIds.add(item.entityId);
      } catch (e) {
        await (_db.update(_db.syncQueue)..where((q) => q.id.equals(item.id)))
            .write(
          SyncQueueCompanion(
            status: const Value('failed'),
            attempts: Value(item.attempts + 1),
            lastError: Value(e.toString()),
          ),
        );
      }
    }
  }

  Future<void> _pushBill(Map<String, dynamic> payload) async {
    await _client.from('bills').upsert(
      payload,
      onConflict: 'id',
      ignoreDuplicates: true,
    );
  }

  Future<void> _pushBillItems(Map<String, dynamic> payload) async {
    final items = payload['items'] as List;
    if (items.isEmpty) return;
    await _client.from('bill_items').upsert(
      items,
      onConflict: 'id',
      ignoreDuplicates: true,
    );
  }

  Future<void> _pushPayment(Map<String, dynamic> payload) async {
    await _client.from('payments').upsert(
      payload,
      onConflict: 'id',
      ignoreDuplicates: true,
    );
  }

  Future<void> _pushStockMovement(Map<String, dynamic> payload) async {
    await _client.from('stock_movements').upsert(
      payload,
      onConflict: 'id',
      ignoreDuplicates: true,
    );
  }

  Future<void> _markBillSynced(String billId) async {
    final row = await _client
        .from('bills')
        .select('bill_no')
        .eq('id', billId)
        .maybeSingle();
    final serverBillNo = row?['bill_no'] as String?;
    await (_db.update(_db.localBills)..where((b) => b.id.equals(billId))).write(
      LocalBillsCompanion(
        syncStatus: const Value('synced'),
        billNo: serverBillNo != null ? Value(serverBillNo) : const Value.absent(),
      ),
    );
  }

  Future<void> _markPaymentSynced(String id) async {
    await (_db.update(_db.localPayments)..where((p) => p.id.equals(id))).write(
      const LocalPaymentsCompanion(syncStatus: Value('synced')),
    );
  }

  Future<void> _markMovementSynced(String id) async {
    await (_db.update(_db.localStockMovements)..where((m) => m.id.equals(id)))
        .write(
      const LocalStockMovementsCompanion(syncStatus: Value('synced')),
    );
  }

  Future<void> _upsertCategory(Map<String, dynamic> row) async {
    final updatedAt = DateTime.parse(row['updated_at'] as String);
    final existing = await (_db.select(_db.localCategories)
          ..where((c) => c.id.equals(row['id'] as String)))
        .getSingleOrNull();
    if (existing != null &&
        !remoteWins(existing.updatedAt, updatedAt)) {
      return;
    }
    await _db.into(_db.localCategories).insertOnConflictUpdate(
      LocalCategoriesCompanion.insert(
        id: row['id'] as String,
        businessId: row['business_id'] as String,
        name: row['name'] as String,
        nameNp: Value(row['name_np'] as String?),
        updatedAt: updatedAt,
        createdAt: Value(
          row['created_at'] == null
              ? null
              : DateTime.parse(row['created_at'] as String),
        ),
      ),
    );
  }

  Future<void> _upsertProduct(Map<String, dynamic> row) async {
    final map = Map<String, dynamic>.from(row);
    final category = map.remove('categories');
    if (category is Map) {
      map['category_name'] = category['name'];
    }
    final updatedAt = DateTime.parse(map['updated_at'] as String);
    final existing = await (_db.select(_db.localProducts)
          ..where((p) => p.id.equals(map['id'] as String)))
        .getSingleOrNull();
    if (existing != null && !remoteWins(existing.updatedAt, updatedAt)) {
      return;
    }
    await _db.into(_db.localProducts).insertOnConflictUpdate(
      LocalProductsCompanion.insert(
        id: map['id'] as String,
        businessId: map['business_id'] as String,
        categoryId: Value(map['category_id'] as String?),
        name: map['name'] as String,
        nameNp: Value(map['name_np'] as String?),
        sku: Value(map['sku'] as String?),
        unit: map['unit'] as String? ?? 'piece',
        costPrice: Value((map['cost_price'] as num?)?.toInt() ?? 0),
        referencePrice: Value((map['reference_price'] as num?)?.toInt() ?? 0),
        imageUrl: Value(map['image_url'] as String?),
        lowStockThreshold:
            Value((map['low_stock_threshold'] as num?)?.toInt() ?? 0),
        stockCached: Value((map['stock_cached'] as num?)?.toInt() ?? 0),
        isActive: Value(map['is_active'] as bool? ?? true),
        categoryName: Value(map['category_name'] as String?),
        updatedAt: updatedAt,
        createdAt: Value(
          map['created_at'] == null
              ? null
              : DateTime.parse(map['created_at'] as String),
        ),
      ),
    );
  }

  Future<void> _upsertCustomerBalance(Map<String, dynamic> row) async {
    final updatedAt = row['updated_at'] != null
        ? DateTime.parse(row['updated_at'] as String)
        : (row['created_at'] != null
            ? DateTime.parse(row['created_at'] as String)
            : DateTime.now().toUtc());
    await _db.into(_db.localCustomers).insertOnConflictUpdate(
      LocalCustomersCompanion.insert(
        id: row['customer_id'] as String,
        businessId: row['business_id'] as String,
        memberId: row['member_id'] as String? ?? '',
        shopName: row['shop_name'] as String,
        contactName: Value(row['contact_name'] as String?),
        phone: Value(row['phone'] as String?),
        address: Value(row['address'] as String?),
        openingBalance: Value((row['opening_balance'] as num?)?.toInt() ?? 0),
        balanceDue: Value((row['balance_due'] as num?)?.toInt() ?? 0),
        updatedAt: updatedAt,
        createdAt: Value(
          row['created_at'] == null
              ? null
              : DateTime.parse(row['created_at'] as String),
        ),
      ),
    );
  }

  Future<void> _upsertRemoteBill(Map<String, dynamic> row) async {
    final map = Map<String, dynamic>.from(row);
    final customer = map.remove('customers');
    final shopName =
        customer is Map ? customer['shop_name'] as String? : null;
    final itemsRaw = map.remove('bill_items');
    final billId = map['id'] as String;

    final local = await (_db.select(_db.localBills)
          ..where((b) => b.id.equals(billId)))
        .getSingleOrNull();
    if (local != null && local.syncStatus == 'pending') {
      final serverBillNo = map['bill_no'] as String;
      await (_db.update(_db.localBills)..where((b) => b.id.equals(billId)))
          .write(
        LocalBillsCompanion(
          syncStatus: const Value('synced'),
          billNo: Value(serverBillNo),
        ),
      );
      return;
    }

    await _db.into(_db.localBills).insertOnConflictUpdate(
      LocalBillsCompanion.insert(
        id: billId,
        businessId: map['business_id'] as String,
        customerId: Value(map['customer_id'] as String?),
        orderId: Value(map['order_id'] as String?),
        billNo: map['bill_no'] as String,
        devicePrefix: Value(map['device_prefix'] as String?),
        itemsTotal: Value((map['items_total'] as num?)?.toInt() ?? 0),
        discount: Value((map['discount'] as num?)?.toInt() ?? 0),
        grandTotal: Value((map['grand_total'] as num?)?.toInt() ?? 0),
        status: map['status'] as String,
        createdBy: map['created_by'] as String,
        customerShopName: Value(shopName),
        syncStatus: const Value('synced'),
        createdAt: Value(
          map['created_at'] == null
              ? DateTime.now().toUtc()
              : DateTime.parse(map['created_at'] as String),
        ),
      ),
    );

    if (itemsRaw is List) {
      for (final item in itemsRaw) {
        final i = item as Map<String, dynamic>;
        await _db.into(_db.localBillItems).insertOnConflictUpdate(
          LocalBillItemsCompanion.insert(
            id: i['id'] as String,
            billId: billId,
            productId: i['product_id'] as String,
            nameSnapshot: i['name_snapshot'] as String,
            qty: i['qty'] as int,
            rate: Value((i['rate'] as num?)?.toInt() ?? 0),
            discount: Value((i['discount'] as num?)?.toInt() ?? 0),
            lineTotal: Value((i['line_total'] as num?)?.toInt() ?? 0),
          ),
        );
      }
    }
  }

  Future<void> _upsertRemotePayment(
    Map<String, dynamic> row, {
    required bool synced,
  }) async {
    final local = await (_db.select(_db.localPayments)
          ..where((p) => p.id.equals(row['id'] as String)))
        .getSingleOrNull();
    if (local != null && local.syncStatus == 'pending') return;

    await _db.into(_db.localPayments).insertOnConflictUpdate(
      LocalPaymentsCompanion.insert(
        id: row['id'] as String,
        businessId: row['business_id'] as String,
        customerId: row['customer_id'] as String,
        billId: Value(row['bill_id'] as String?),
        amount: (row['amount'] as num).toInt(),
        method: row['method'] as String,
        refNote: Value(row['ref_note'] as String?),
        receivedBy: row['received_by'] as String,
        syncStatus: Value(synced ? 'synced' : 'pending'),
        createdAt: Value(
          row['created_at'] == null
              ? DateTime.now().toUtc()
              : DateTime.parse(row['created_at'] as String),
        ),
      ),
    );
  }

  Future<void> _upsertRemoteMovement(
    Map<String, dynamic> row, {
    required bool synced,
  }) async {
    final map = Map<String, dynamic>.from(row);
    final member = map.remove('members');
    if (member is Map) {
      map['created_by_name'] = member['display_name'];
    }
    final local = await (_db.select(_db.localStockMovements)
          ..where((m) => m.id.equals(map['id'] as String)))
        .getSingleOrNull();
    if (local != null && local.syncStatus == 'pending') return;

    await _db.into(_db.localStockMovements).insertOnConflictUpdate(
      LocalStockMovementsCompanion.insert(
        id: map['id'] as String,
        businessId: map['business_id'] as String,
        productId: map['product_id'] as String,
        type: map['type'] as String,
        qtyDelta: (map['qty_delta'] as num).toInt(),
        reason: Value(map['reason'] as String?),
        createdBy: map['created_by'] as String,
        createdByName: Value(map['created_by_name'] as String?),
        syncStatus: Value(synced ? 'synced' : 'pending'),
        createdAt: Value(
          map['created_at'] == null
              ? DateTime.now().toUtc()
              : DateTime.parse(map['created_at'] as String),
        ),
      ),
    );
  }

  String newId() => _uuid.v4();
}
