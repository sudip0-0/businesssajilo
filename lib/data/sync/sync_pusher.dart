import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/logging/app_log.dart';
import '../local/app_database.dart';
import 'sync_backoff.dart';
import 'sync_helpers.dart';

const _independentBatchSize = 4;

class SyncPusher {
  SyncPusher({required AppDatabase db, required SupabaseClient client})
    : _db = db,
      _client = client;

  final AppDatabase _db;
  final SupabaseClient _client;

  Future<int> push() async {
    final queue = await _db.pendingQueue();
    final unsynced = await _db.unsyncedQueue();
    final blockedIds = unsynced.map((q) => q.entityId).toSet();
    final syncedIds = <String>{};
    final now = DateTime.now().toUtc();
    var uploadedCount = 0;
    final independent = <SyncQueueData>[];

    Future<int> process(SyncQueueData item) async {
      try {
        final payload = jsonDecode(item.payloadJson) as Map<String, dynamic>;
        switch (item.entityType) {
          case 'bill':
            await _pushBill(item.entityId, payload);
          case 'bill_items':
            throw StateError('legacy bill_items queue entry rejected');
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
        return 1;
      } catch (e, st) {
        final attempts = item.attempts + 1;
        final terminal = attempts >= syncMaxAttempts;
        final truncated = truncateSyncError(e);
        await (_db.update(
          _db.syncQueue,
        )..where((q) => q.id.equals(item.id))).write(
          SyncQueueCompanion(
            status: Value(terminal ? 'failed' : 'pending'),
            attempts: Value(attempts),
            lastError: Value(truncated),
            nextAttemptAt: Value(
              DateTime.now().toUtc().add(backoffForAttempts(attempts)),
            ),
          ),
        );
        if (terminal) {
          await _db.setLocalEntitySyncStatus(
            item.entityType,
            item.entityId,
            'failed',
          );
          AppLog.error(
            'Sync queue item terminal failure',
            error: e,
            stackTrace: st,
            extras: {
              'entityType': item.entityType,
              'entityId': item.entityId,
              'attempts': attempts,
              'lastError': truncated,
            },
          );
        } else {
          AppLog.warn('Sync queue item retry scheduled', e, st, {
            'entityType': item.entityType,
            'entityId': item.entityId,
            'attempts': attempts,
            'nextAttemptInSec': backoffForAttempts(attempts).inSeconds,
          });
        }
        return 0;
      }
    }

    for (final item in queue) {
      if (item.nextAttemptAt != null && item.nextAttemptAt!.isAfter(now)) {
        continue;
      }
      if (item.dependsOnId != null &&
          !syncedIds.contains(item.dependsOnId) &&
          blockedIds.contains(item.dependsOnId)) {
        continue;
      }
      final canBatch =
          item.dependsOnId == null &&
          (item.entityType == 'stock_movement' || item.entityType == 'payment');
      if (canBatch) {
        independent.add(item);
      } else {
        uploadedCount += await process(item);
      }
    }

    for (var i = 0; i < independent.length; i += _independentBatchSize) {
      final end = i + _independentBatchSize < independent.length
          ? i + _independentBatchSize
          : independent.length;
      final chunk = independent.sublist(i, end);
      final results = await Future.wait(chunk.map(process));
      for (final n in results) {
        uploadedCount += n;
      }
    }

    return uploadedCount;
  }

  /// Pushes a bill through the transactional `create_bill` RPC (or
  /// `record_customer_sale` for amount-only manual sales). The RPC is
  /// idempotent on the bill id; replays return the existing bill. The
  /// server-assigned `bill_no` finalizes the provisional local number.
  /// When the payload embeds a payment, that local payment is marked synced.
  Future<void> _pushBill(String billId, Map<String, dynamic> payload) async {
    final local = await (_db.select(
      _db.localBills,
    )..where((b) => b.id.equals(billId))).getSingleOrNull();
    var stamped = sanitizeBillPayload(
      stampOccurredAt(payload, local?.createdAt),
    );
    stamped = await _withCustomerSnapshot(
      stamped,
      billCustomerId: local?.customerId,
      billShopName: local?.customerShopName,
    );
    final result = stamped['manual_sale'] == true
        ? await _client.rpc<dynamic>(
            'record_customer_sale',
            params: {'p': stamped},
          )
        : await _client.rpc<dynamic>('create_bill', params: {'p': stamped});
    Map<String, dynamic> map = const {};
    try {
      map = mapRpcObject(result);
    } catch (e, st) {
      AppLog.warn(
        'bill RPC returned a non-object; marking local synced',
        e,
        st,
        {'billId': billId},
      );
    }
    final billRaw = map['bill'];
    final bill = billRaw is Map ? Map<String, dynamic>.from(billRaw) : null;
    final serverBillNo = bill?['bill_no'] as String?;
    final serverStatus = bill?['status'] as String?;
    final serverCustomerId = bill?['customer_id'] as String?;
    final serverGuest = (bill?['guest_name'] as String?)?.trim();
    final payloadGuest = (payload['guest_name'] as String?)?.trim();
    final guestName = (serverGuest != null && serverGuest.isNotEmpty)
        ? serverGuest
        : (payloadGuest != null && payloadGuest.isNotEmpty
              ? payloadGuest
              : null);
    await (_db.update(_db.localBills)..where((b) => b.id.equals(billId))).write(
      LocalBillsCompanion(
        syncStatus: const Value('synced'),
        billNo: serverBillNo != null
            ? Value(serverBillNo)
            : const Value.absent(),
        status: serverStatus != null
            ? Value(serverStatus)
            : const Value.absent(),
        customerId: serverCustomerId != null
            ? Value(serverCustomerId)
            : const Value.absent(),
        customerShopName: guestName != null
            ? Value(guestName)
            : const Value.absent(),
      ),
    );
    await _reconcileLocalCustomerBalance(
      grandTotal: local?.grandTotal ?? 0,
      localCustomerId: local?.customerId,
      serverCustomerId: serverCustomerId,
      payment: payload['payment'],
    );
    final payment = payload['payment'];
    if (payment is Map && payment['id'] is String) {
      await _markPaymentSynced(payment['id'] as String);
    }
  }

  Future<Map<String, dynamic>> _withCustomerSnapshot(
    Map<String, dynamic> payload, {
    String? billCustomerId,
    String? billShopName,
  }) async {
    final id = (payload['customer_id'] as String?)?.trim().isNotEmpty == true
        ? (payload['customer_id'] as String).trim()
        : billCustomerId;
    if (id == null || id.isEmpty) {
      return withCustomerSnapshot(payload, shopName: billShopName);
    }
    final local = await (_db.select(
      _db.localCustomers,
    )..where((c) => c.id.equals(id))).getSingleOrNull();
    return withCustomerSnapshot(
      payload,
      shopName: local?.shopName ?? billShopName,
      phone: local?.phone,
    );
  }

  Future<void> _reconcileLocalCustomerBalance({
    required int grandTotal,
    String? localCustomerId,
    String? serverCustomerId,
    Object? payment,
  }) async {
    if (serverCustomerId == null || serverCustomerId.isEmpty) return;
    var paymentAmount = 0;
    String? paymentId;
    if (payment is Map) {
      paymentAmount = (payment['amount'] as num?)?.toInt() ?? 0;
      if (payment['id'] is String) paymentId = payment['id'] as String;
    }
    if (paymentId != null &&
        localCustomerId != null &&
        localCustomerId != serverCustomerId) {
      await (_db.update(_db.localPayments)
            ..where((p) => p.id.equals(paymentId!)))
          .write(LocalPaymentsCompanion(customerId: Value(serverCustomerId)));
    }
    if (localCustomerId == serverCustomerId) return;
    final net = grandTotal - paymentAmount;
    if (net == 0) return;
    if (localCustomerId != null && localCustomerId.isNotEmpty) {
      await _db.customStatement(
        'UPDATE local_customers SET balance_due = balance_due - ? WHERE id = ?',
        [net, localCustomerId],
      );
    }
    await _db.customStatement(
      'UPDATE local_customers SET balance_due = balance_due + ? WHERE id = ?',
      [net, serverCustomerId],
    );
  }

  Future<void> _pushPayment(Map<String, dynamic> payload) async {
    await _client.rpc<dynamic>('record_payment', params: {'p': payload});
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
}
