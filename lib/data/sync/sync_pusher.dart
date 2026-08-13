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
              terminal
                  ? null
                  : DateTime.now().toUtc().add(backoffForAttempts(attempts)),
            ),
          ),
        );
        if (terminal) {
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
    final result = payload['manual_sale'] == true
        ? await _client.rpc<dynamic>(
            'record_customer_sale',
            params: {'p': payload},
          )
        : await _client.rpc<dynamic>('create_bill', params: {'p': payload});
    final map = result as Map<String, dynamic>;
    final bill = map['bill'] as Map<String, dynamic>?;
    final serverBillNo = bill?['bill_no'] as String?;
    final serverStatus = bill?['status'] as String?;
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
        customerShopName: guestName != null
            ? Value(guestName)
            : const Value.absent(),
      ),
    );
    final payment = payload['payment'];
    if (payment is Map && payment['id'] is String) {
      await _markPaymentSynced(payment['id'] as String);
    }
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
