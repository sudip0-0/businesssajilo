import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/logging/app_log.dart';
import '../local/app_database.dart';
import 'sync_backoff.dart';
import 'sync_constants.dart';
import 'sync_helpers.dart';

const _independentBatchSize = 4;

class SyncPusher {
  SyncPusher({
    required AppDatabase db,
    required SupabaseClient client,
    bool Function()? isActive,
    Duration requestTimeout = const Duration(seconds: 15),
  }) : _db = db,
       _client = client,
       _requestTimeout = requestTimeout,
       _isActive = isActive;

  final AppDatabase _db;
  final SupabaseClient _client;
  final bool Function()? _isActive;
  final Duration _requestTimeout;

  bool get _active => _isActive?.call() ?? true;

  Future<int> push() async {
    final queue = await _db.pendingQueue();
    final unsynced = await _db.unsyncedQueue();
    final blockedIds = unsynced.map((q) => q.entityId).toSet();
    final syncedIds = <String>{};
    final now = DateTime.now().toUtc();
    var uploadedCount = 0;
    final remaining = List<SyncQueueData>.of(queue);

    Future<int> process(SyncQueueData item) async {
      if (!_active) return 0;
      try {
        final payload = jsonDecode(item.payloadJson) as Map<String, dynamic>;
        switch (item.entityType) {
          case 'bill':
            await _pushBill(item.entityId, payload, item.id);
          case 'bill_items':
            throw StateError('legacy bill_items queue entry rejected');
          case 'payment':
            await _pushPayment(item.entityId, payload, item.id);
          case 'stock_movement':
            await _pushStockMovement(payload);
            await _markMovementSynced(item.entityId);
          default:
            throw StateError('Unsupported sync entity: ${item.entityType}');
        }

        if (item.entityType != 'bill' && item.entityType != 'payment') {
          await (_db.update(_db.syncQueue)..where((q) => q.id.equals(item.id)))
              .write(const SyncQueueCompanion(status: Value('synced')));
        }
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

    while (remaining.isNotEmpty) {
      final ready = remaining.where((item) {
        if (item.nextAttemptAt != null && item.nextAttemptAt!.isAfter(now)) {
          return false;
        }
        return item.dependsOnId == null ||
            syncedIds.contains(item.dependsOnId) ||
            !blockedIds.contains(item.dependsOnId);
      }).toList();
      if (ready.isEmpty) break;
      final independent = <SyncQueueData>[];
      for (final item in ready) {
        remaining.remove(item);
        final canBatch =
            item.dependsOnId == null &&
            (item.entityType == 'stock_movement' ||
                item.entityType == 'payment');
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
        final results = await Future.wait(
          independent.sublist(i, end).map(process),
        );
        for (final n in results) {
          uploadedCount += n;
        }
      }
    }

    return uploadedCount;
  }

  /// Pushes a bill through the transactional `create_bill` RPC (or
  /// `record_customer_sale` for amount-only manual sales). The RPC is
  /// idempotent on the bill id; replays return the existing bill. The
  /// server-assigned `bill_no` finalizes the provisional local number.
  /// When the payload embeds a payment, that local payment is marked synced.
  Future<void> _pushBill(
    String billId,
    Map<String, dynamic> payload,
    int queueId,
  ) async {
    if (payload['id'] != billId) {
      throw const FormatException('Bill queue identity mismatch');
    }
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
    if (!_active) throw StateError('Sync session changed');
    final result = await _client
        .rpc<dynamic>(
          stamped['manual_sale'] == true
              ? 'record_customer_sale'
              : 'create_bill',
          params: {'p': stamped},
        )
        .timeout(_requestTimeout);
    final map = mapRpcObject(result);
    final bill = validateSyncedBill(map['bill'], billId);
    final serverBillNo = bill['bill_no'] as String;
    final serverStatus = bill['status'] as String;
    final serverCustomerId = bill['customer_id'] as String?;
    final serverGuest = (bill['guest_name'] as String?)?.trim();
    final payloadGuest = (payload['guest_name'] as String?)?.trim();
    final guestName = (serverGuest != null && serverGuest.isNotEmpty)
        ? serverGuest
        : (payloadGuest != null && payloadGuest.isNotEmpty
              ? payloadGuest
              : null);
    await _db.transaction(() async {
      await (_db.update(
        _db.localBills,
      )..where((b) => b.id.equals(billId))).write(
        LocalBillsCompanion(
          syncStatus: const Value('synced'),
          billNo: Value(serverBillNo),
          status: Value(serverStatus),
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
      await (_db.update(_db.syncQueue)..where((q) => q.id.equals(queueId)))
          .write(const SyncQueueCompanion(status: Value('synced')));
    });
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

  Future<void> _pushPayment(
    String id,
    Map<String, dynamic> payload,
    int queueId,
  ) async {
    final customerId = payload['customer_id'];
    final amount = payload['amount'];
    final method = payload['method'];
    if (payload['id'] != id ||
        customerId is! String ||
        customerId.trim().isEmpty ||
        amount is! int ||
        amount <= 0 ||
        method is! String) {
      throw const FormatException('Invalid payment queue identity');
    }
    final local = await (_db.select(
      _db.localPayments,
    )..where((p) => p.id.equals(id))).getSingleOrNull();
    if (local != null &&
        (local.customerId != customerId ||
            (payload['business_id'] != null &&
                local.businessId != payload['business_id']) ||
            (payload['received_by'] != null &&
                local.receivedBy != payload['received_by']))) {
      throw const FormatException('Invalid payment queue identity');
    }
    if (!_active) throw StateError('Sync session changed');
    final result = await _client
        .rpc<dynamic>('record_payment', params: {'p': payload})
        .timeout(_requestTimeout);
    final split =
        payload['allocate'] == 'oldest_first' && payload['bill_id'] == null;
    final payment = validateSyncedPayment(
      mapRpcObject(result)['payment'],
      expectedId: id,
      expectedCustomerId: customerId,
      requestedAmount: amount,
      expectedMethod: method,
      allowsSplit: split,
      expectedBillId: payload['bill_id'] as String?,
      expectedBusinessId:
          local?.businessId ?? payload['business_id'] as String?,
      expectedReceivedBy:
          local?.receivedBy ?? payload['received_by'] as String?,
    );
    final createdAt = DateTime.parse(payment['created_at'] as String).toUtc();
    await _db.transaction(() async {
      await _db
          .into(_db.localPayments)
          .insertOnConflictUpdate(
            LocalPaymentsCompanion.insert(
              id: id,
              businessId: payment['business_id'] as String,
              customerId: customerId,
              billId: Value(payment['bill_id'] as String?),
              amount: (payment['amount'] as num).toInt(),
              method: payment['method'] as String,
              refNote: Value(payment['ref_note'] as String?),
              receivedBy: payment['received_by'] as String,
              syncStatus: const Value('synced'),
              createdAt: Value(createdAt),
            ),
          );
      await (_db.update(_db.syncQueue)..where((q) => q.id.equals(queueId)))
          .write(const SyncQueueCompanion(status: Value('synced')));
      if (split) {
        final watermark = await _db.watermark('payments');
        if (watermark != null && !watermark.isBefore(createdAt)) {
          await _db.setWatermark(
            'payments',
            createdAt.subtract(const Duration(seconds: 1)),
          );
        }
      }
      final bootstrapTable = await _db.metaValue(syncMetaBootstrapTable);
      if (bootstrapTable == 'payments') {
        await _db.setMetaValue(syncMetaBootstrapOffset, '0');
      }
    });
  }

  Future<void> _pushStockMovement(Map<String, dynamic> payload) async {
    await _client
        .from('stock_movements')
        .upsert(payload, onConflict: 'id', ignoreDuplicates: true)
        .timeout(_requestTimeout);
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
