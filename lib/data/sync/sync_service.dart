import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../local/app_database.dart';
import 'sync_helpers.dart';
import 'sync_merge.dart';

const _maxAttempts = 5;
const _maxBackoff = Duration(minutes: 5);
const _uuid = Uuid();

/// Page size for Supabase bootstrap/delta pulls.
const syncPullPageSize = 500;

Duration backoffForAttempts(int attempts) {
  if (attempts <= 0) return Duration.zero;
  final seconds = attempts >= 9 ? _maxBackoff.inSeconds : 1 << attempts;
  final delay = Duration(seconds: seconds);
  return delay > _maxBackoff ? _maxBackoff : delay;
}

class SyncService {
  SyncService({
    required AppDatabase db,
    required SupabaseClient client,
    Connectivity? connectivity,
  }) : _db = db,
       _client = client,
       _connectivity = connectivity ?? Connectivity();

  final AppDatabase _db;
  final SupabaseClient _client;
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  final SyncCoalesce _coalesce = SyncCoalesce();

  Future<void> init(String deviceId) async {
    await _db.ensureDeviceMeta(deviceId);
    _connectivitySub ??= _connectivity.onConnectivityChanged.listen((_) {
      unawaited(syncNow());
    });
    // Initial sync is best-effort: a network failure must not break init.
    try {
      await syncNow();
    } catch (e) {
      debugPrint('Initial sync failed (will retry later): $e');
    }
  }

  /// Number of terminally failed queue items.
  Future<int> failedCount() => _db.failedCount();

  /// Resets failed items and triggers a sync.
  Future<void> retryFailed() async {
    await _db.retryFailed();
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
    if (_coalesce.syncing) {
      _coalesce.markQueuedIfBusy();
      return;
    }
    if (!await isOnline) return;
    // Re-check after the async online probe — another sync may have started.
    if (!_coalesce.tryEnter()) return;
    try {
      do {
        _coalesce.clearQueued();
        await _pull();
        await _push();
        await _pull();
      } while (_coalesce.shouldRepeat);
    } finally {
      _coalesce.end();
    }
  }

  Future<void> _pull() async {
    final now = DateTime.now().toUtc();
    final hasWatermarks = await _db
        .select(_db.syncWatermarks)
        .get()
        .then((r) => r.isNotEmpty);

    if (!hasWatermarks) {
      await _bootstrap();
    } else {
      await _pullDelta();
    }

    await _db.setWatermark('_global', now);
  }

  /// Fetches all pages from [buildPage], applying [onPage] after each page.
  Future<void> _pullPaged({
    required Future<List<Map<String, dynamic>>> Function(int from, int to)
    buildPage,
    required Future<void> Function(List<Map<String, dynamic>> rows) onPage,
    int pageSize = syncPullPageSize,
  }) async {
    var offset = 0;
    while (true) {
      final rows = await buildPage(offset, offset + pageSize - 1);
      if (rows.isEmpty) break;
      await onPage(rows);
      if (rows.length < pageSize) break;
      offset += pageSize;
    }
  }

  List<Map<String, dynamic>> _asMaps(dynamic rows) {
    return (rows as List)
        .map((r) => Map<String, dynamic>.from(r as Map))
        .toList();
  }

  Future<void> _bootstrap() async {
    // Each table's watermark is committed right after its pull succeeds so a
    // partial failure never skips data on the next attempt.
    var ts = DateTime.now().toUtc();
    await _pullPaged(
      buildPage: (from, to) async {
        final rows = await _client
            .from('categories')
            .select()
            .order('id')
            .range(from, to);
        return _asMaps(rows);
      },
      onPage: _upsertCategoriesBatch,
    );
    await _db.setWatermark('categories', ts);

    ts = DateTime.now().toUtc();
    await _pullPaged(
      buildPage: (from, to) async {
        final rows = await _client
            .from('products')
            .select('*, categories(name)')
            .order('id')
            .range(from, to);
        return _asMaps(rows);
      },
      onPage: _upsertProductsBatch,
    );
    await _db.setWatermark('products', ts);

    ts = DateTime.now().toUtc();
    await _pullPaged(
      buildPage: (from, to) async {
        final rows = await _client
            .from('customer_balances')
            .select()
            .order('customer_id')
            .range(from, to);
        return _asMaps(rows);
      },
      onPage: _upsertCustomerBalancesBatch,
    );
    await _db.setWatermark('customers', ts);

    ts = DateTime.now().toUtc();
    await _pullPaged(
      buildPage: (from, to) async {
        final rows = await _client
            .from('bills')
            .select('*, customers(shop_name), bill_items(*)')
            .order('created_at', ascending: false)
            .range(from, to);
        return _asMaps(rows);
      },
      onPage: _upsertRemoteBillsBatch,
    );
    await _db.setWatermark('bills', ts);

    ts = DateTime.now().toUtc();
    await _pullPaged(
      buildPage: (from, to) async {
        final rows = await _client
            .from('payments')
            .select()
            .order('id')
            .range(from, to);
        return _asMaps(rows);
      },
      onPage: (rows) => _upsertRemotePaymentsBatch(rows, synced: true),
    );
    await _db.setWatermark('payments', ts);

    ts = DateTime.now().toUtc();
    await _pullPaged(
      buildPage: (from, to) async {
        final rows = await _client
            .from('stock_movements')
            .select('*, members(display_name)')
            .order('id')
            .range(from, to);
        return _asMaps(rows);
      },
      onPage: (rows) => _upsertRemoteMovementsBatch(rows, synced: true),
    );
    await _db.setWatermark('stock_movements', ts);
  }

  Future<void> _pullDelta() async {
    // Per-table watermarks are committed right after each table's pull
    // succeeds so a failure mid-way doesn't lose deltas for earlier tables.
    final catWatermark = await _db.watermark('categories');
    if (catWatermark != null) {
      final ts = DateTime.now().toUtc();
      final iso = catWatermark.toIso8601String();
      await _pullPaged(
        buildPage: (from, to) async {
          final rows = await _client
              .from('categories')
              .select()
              .gt('updated_at', iso)
              .order('id')
              .range(from, to);
          return _asMaps(rows);
        },
        onPage: _upsertCategoriesBatch,
      );
      await _db.setWatermark('categories', ts);
    }

    final prodWatermark = await _db.watermark('products');
    if (prodWatermark != null) {
      final ts = DateTime.now().toUtc();
      final iso = prodWatermark.toIso8601String();
      await _pullPaged(
        buildPage: (from, to) async {
          final rows = await _client
              .from('products')
              .select('*, categories(name)')
              .gt('updated_at', iso)
              .order('id')
              .range(from, to);
          return _asMaps(rows);
        },
        onPage: _upsertProductsBatch,
      );
      await _db.setWatermark('products', ts);
    }

    final custWatermark = await _db.watermark('customers');
    if (custWatermark != null) {
      final ts = DateTime.now().toUtc();
      final iso = custWatermark.toIso8601String();
      await _pullPaged(
        buildPage: (from, to) async {
          final rows = await _client
              .from('customer_balances')
              .select()
              .gt('updated_at', iso)
              .order('customer_id')
              .range(from, to);
          return _asMaps(rows);
        },
        onPage: _upsertCustomerBalancesBatch,
      );
      await _db.setWatermark('customers', ts);
    }

    final billWatermark = await _db.watermark('bills');
    if (billWatermark != null) {
      final ts = DateTime.now().toUtc();
      final iso = billWatermark.toIso8601String();
      await _pullPaged(
        buildPage: (from, to) async {
          final rows = await _client
              .from('bills')
              .select('*, customers(shop_name), bill_items(*)')
              .gte('updated_at', iso)
              .order('created_at', ascending: false)
              .range(from, to);
          return _asMaps(rows);
        },
        onPage: _upsertRemoteBillsBatch,
      );
      await _db.setWatermark('bills', ts);
    }

    final payWatermark = await _db.watermark('payments');
    if (payWatermark != null) {
      final ts = DateTime.now().toUtc();
      final iso = payWatermark.toIso8601String();
      await _pullPaged(
        buildPage: (from, to) async {
          final rows = await _client
              .from('payments')
              .select()
              .gt('created_at', iso)
              .order('id')
              .range(from, to);
          return _asMaps(rows);
        },
        onPage: (rows) => _upsertRemotePaymentsBatch(rows, synced: true),
      );
      await _db.setWatermark('payments', ts);
    }

    final movWatermark = await _db.watermark('stock_movements');
    if (movWatermark != null) {
      final ts = DateTime.now().toUtc();
      final iso = movWatermark.toIso8601String();
      await _pullPaged(
        buildPage: (from, to) async {
          final rows = await _client
              .from('stock_movements')
              .select('*, members(display_name)')
              .gt('created_at', iso)
              .order('id')
              .range(from, to);
          return _asMaps(rows);
        },
        onPage: (rows) => _upsertRemoteMovementsBatch(rows, synced: true),
      );
      await _db.setWatermark('stock_movements', ts);
    }
  }

  Future<void> _push() async {
    final queue = await _db.pendingQueue();
    final unsynced = await _db.unsyncedQueue();
    final blockedIds = unsynced.map((q) => q.entityId).toSet();
    final syncedIds = <String>{};
    final now = DateTime.now().toUtc();

    for (final item in queue) {
      // Exponential backoff: skip until the item's backoff window elapsed.
      if (item.nextAttemptAt != null && item.nextAttemptAt!.isAfter(now)) {
        continue;
      }

      if (item.dependsOnId != null &&
          !syncedIds.contains(item.dependsOnId) &&
          blockedIds.contains(item.dependsOnId)) {
        continue;
      }

      try {
        final payload = jsonDecode(item.payloadJson) as Map<String, dynamic>;
        switch (item.entityType) {
          case 'bill':
            await _pushBill(item.entityId, payload);
          case 'bill_items':
            // Legacy queue entries; bills now carry items via the RPC.
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
        blockedIds.remove(item.entityId);
      } catch (e) {
        final attempts = item.attempts + 1;
        final terminal = attempts >= _maxAttempts;
        await (_db.update(
          _db.syncQueue,
        )..where((q) => q.id.equals(item.id))).write(
          SyncQueueCompanion(
            status: Value(terminal ? 'failed' : 'pending'),
            attempts: Value(attempts),
            lastError: Value(truncateSyncError(e)),
            nextAttemptAt: Value(
              terminal
                  ? null
                  : DateTime.now().toUtc().add(backoffForAttempts(attempts)),
            ),
          ),
        );
      }
    }
  }

  /// Pushes a bill through the transactional `create_bill` RPC. The RPC is
  /// idempotent on the bill id; replays return the existing bill. The
  /// server-assigned `bill_no` finalizes the provisional local number.
  /// When the payload embeds a payment, that local payment is marked synced.
  Future<void> _pushBill(String billId, Map<String, dynamic> payload) async {
    final result = await _client.rpc<dynamic>(
      'create_bill',
      params: {'p': payload},
    );
    final map = result as Map<String, dynamic>;
    final bill = map['bill'] as Map<String, dynamic>?;
    final serverBillNo = bill?['bill_no'] as String?;
    final serverStatus = bill?['status'] as String?;
    await (_db.update(_db.localBills)..where((b) => b.id.equals(billId))).write(
      LocalBillsCompanion(
        syncStatus: const Value('synced'),
        billNo: serverBillNo != null
            ? Value(serverBillNo)
            : const Value.absent(),
        status: serverStatus != null
            ? Value(serverStatus)
            : const Value.absent(),
      ),
    );
    final payment = payload['payment'];
    if (payment is Map && payment['id'] is String) {
      await _markPaymentSynced(payment['id'] as String);
    }
  }

  Future<void> _pushBillItems(Map<String, dynamic> payload) async {
    final items = payload['items'] as List;
    if (items.isEmpty) return;
    await _client
        .from('bill_items')
        .upsert(items, onConflict: 'id', ignoreDuplicates: true);
  }

  Future<void> _pushPayment(Map<String, dynamic> payload) async {
    await _client
        .from('payments')
        .upsert(payload, onConflict: 'id', ignoreDuplicates: true);
  }

  Future<void> _pushStockMovement(Map<String, dynamic> payload) async {
    await _client
        .from('stock_movements')
        .upsert(payload, onConflict: 'id', ignoreDuplicates: true);
  }

  Future<void> _markPaymentSynced(String id) async {
    await (_db.update(_db.localPayments)..where((p) => p.id.equals(id))).write(
      const LocalPaymentsCompanion(syncStatus: Value('synced')),
    );
  }

  Future<void> _markMovementSynced(String id) async {
    await (_db.update(_db.localStockMovements)..where((m) => m.id.equals(id)))
        .write(const LocalStockMovementsCompanion(syncStatus: Value('synced')));
  }

  Future<void> _upsertCategoriesBatch(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    final ids = rows.map((r) => r['id'] as String).toList();
    final existing = await (_db.select(
      _db.localCategories,
    )..where((c) => c.id.isIn(ids))).get();
    final byId = {for (final e in existing) e.id: e};

    final companions = <LocalCategoriesCompanion>[];
    for (final row in rows) {
      final updatedAt = DateTime.parse(row['updated_at'] as String);
      final local = byId[row['id'] as String];
      if (local != null && !remoteWins(local.updatedAt, updatedAt)) continue;
      companions.add(
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
    if (companions.isEmpty) return;
    await _db.transaction(() async {
      for (final c in companions) {
        await _db.into(_db.localCategories).insertOnConflictUpdate(c);
      }
    });
  }

  Future<void> _upsertProductsBatch(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    final ids = rows.map((r) => r['id'] as String).toList();
    final existing = await (_db.select(
      _db.localProducts,
    )..where((p) => p.id.isIn(ids))).get();
    final byId = {for (final e in existing) e.id: e};

    final companions = <LocalProductsCompanion>[];
    for (final row in rows) {
      final map = Map<String, dynamic>.from(row);
      final category = map.remove('categories');
      if (category is Map) {
        map['category_name'] = category['name'];
      }
      final updatedAt = DateTime.parse(map['updated_at'] as String);
      final local = byId[map['id'] as String];
      if (local != null && !remoteWins(local.updatedAt, updatedAt)) continue;
      companions.add(
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
          lowStockThreshold: Value(
            (map['low_stock_threshold'] as num?)?.toInt() ?? 0,
          ),
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
    if (companions.isEmpty) return;
    await _db.transaction(() async {
      for (final c in companions) {
        await _db.into(_db.localProducts).insertOnConflictUpdate(c);
      }
    });
  }

  Future<void> _upsertCustomerBalancesBatch(
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty) return;
    await _db.transaction(() async {
      for (final row in rows) {
        final updatedAt = row['updated_at'] != null
            ? DateTime.parse(row['updated_at'] as String)
            : (row['created_at'] != null
                  ? DateTime.parse(row['created_at'] as String)
                  : DateTime.now().toUtc());
        await _db
            .into(_db.localCustomers)
            .insertOnConflictUpdate(
              LocalCustomersCompanion.insert(
                id: row['customer_id'] as String,
                businessId: row['business_id'] as String,
                memberId: row['member_id'] as String? ?? '',
                shopName: row['shop_name'] as String,
                contactName: Value(row['contact_name'] as String?),
                phone: Value(row['phone'] as String?),
                address: Value(row['address'] as String?),
                openingBalance: Value(
                  (row['opening_balance'] as num?)?.toInt() ?? 0,
                ),
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
    });
  }

  Future<void> _upsertRemoteBillsBatch(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    final ids = rows.map((r) => r['id'] as String).toList();
    final existing = await (_db.select(
      _db.localBills,
    )..where((b) => b.id.isIn(ids))).get();
    final byId = {for (final e in existing) e.id: e};

    await _db.transaction(() async {
      for (final row in rows) {
        final map = Map<String, dynamic>.from(row);
        final customer = map.remove('customers');
        final shopName = customer is Map
            ? customer['shop_name'] as String?
            : null;
        final itemsRaw = map.remove('bill_items');
        final billId = map['id'] as String;

        final local = byId[billId];
        if (local != null && local.syncStatus == 'pending') {
          // Server already has this bill (idempotent replay) — adopt the final
          // bill number and status but keep the local row otherwise.
          final serverBillNo = map['bill_no'] as String;
          await (_db.update(
            _db.localBills,
          )..where((b) => b.id.equals(billId))).write(
            LocalBillsCompanion(
              syncStatus: const Value('synced'),
              billNo: Value(serverBillNo),
              status: Value(map['status'] as String),
            ),
          );
          continue;
        }

        await _db
            .into(_db.localBills)
            .insertOnConflictUpdate(
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
            await _db
                .into(_db.localBillItems)
                .insertOnConflictUpdate(
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
    });
  }

  Future<void> _upsertRemotePaymentsBatch(
    List<Map<String, dynamic>> rows, {
    required bool synced,
  }) async {
    if (rows.isEmpty) return;
    final ids = rows.map((r) => r['id'] as String).toList();
    final existing = await (_db.select(
      _db.localPayments,
    )..where((p) => p.id.isIn(ids))).get();
    final pendingIds = {
      for (final e in existing)
        if (e.syncStatus == 'pending') e.id,
    };

    await _db.transaction(() async {
      for (final row in rows) {
        final id = row['id'] as String;
        if (pendingIds.contains(id)) continue;
        await _db
            .into(_db.localPayments)
            .insertOnConflictUpdate(
              LocalPaymentsCompanion.insert(
                id: id,
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
    });
  }

  Future<void> _upsertRemoteMovementsBatch(
    List<Map<String, dynamic>> rows, {
    required bool synced,
  }) async {
    if (rows.isEmpty) return;
    final ids = rows.map((r) => r['id'] as String).toList();
    final existing = await (_db.select(
      _db.localStockMovements,
    )..where((m) => m.id.isIn(ids))).get();
    final pendingIds = {
      for (final e in existing)
        if (e.syncStatus == 'pending') e.id,
    };

    await _db.transaction(() async {
      for (final row in rows) {
        final map = Map<String, dynamic>.from(row);
        final member = map.remove('members');
        if (member is Map) {
          map['created_by_name'] = member['display_name'];
        }
        final id = map['id'] as String;
        if (pendingIds.contains(id)) continue;
        await _db
            .into(_db.localStockMovements)
            .insertOnConflictUpdate(
              LocalStockMovementsCompanion.insert(
                id: id,
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
    });
  }

  String newId() => _uuid.v4();
}
