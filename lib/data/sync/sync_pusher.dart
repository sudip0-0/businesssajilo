import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../local/app_database.dart';
import 'sync_backoff.dart';
import 'sync_helpers.dart';

class SyncPusher {
  SyncPusher({required AppDatabase db, required SupabaseClient client})
    : _db = db,
      _client = client;

  final AppDatabase _db;
  final SupabaseClient _client;

  Future<void> push() async {
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
        final terminal = attempts >= syncMaxAttempts;
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
}
