import 'dart:async';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/pagination.dart';
import '../../domain/enums.dart';
import '../../domain/models/payment.dart';
import '../local/app_database.dart';
import '../local/local_mappers.dart';
import '../repositories/payments_repository.dart';
import 'sync_service.dart';

class SyncingPaymentsRepository implements PaymentsRepository {
  SyncingPaymentsRepository({
    required AppDatabase db,
    required SyncService sync,
    required String businessId,
  }) : _db = db,
       _sync = sync,
       _businessId = businessId;

  final AppDatabase _db;
  final SyncService _sync;
  final String _businessId;
  static const _uuid = Uuid();

  @override
  Future<List<Payment>> listByCustomer(
    String customerId, {
    int offset = 0,
    int limit = kListPageSize,
  }) async {
    final rows =
        await (_db.select(_db.localPayments)
              ..where((p) => p.customerId.equals(customerId))
              ..orderBy([(p) => OrderingTerm.desc(p.createdAt)])
              ..limit(limit, offset: offset))
            .get();
    return rows.map(mapLocalPayment).toList();
  }

  @override
  Future<Payment> record({
    String? id,
    required String customerId,
    required int amount,
    required PaymentMethod method,
    String? refNote,
    String? billId,
    required String receivedByMemberId,
    bool enqueueRemote = true,
  }) async {
    final paymentId = id ?? _uuid.v4();
    await _db.transaction(() async {
      await _db
          .into(_db.localPayments)
          .insert(
            LocalPaymentsCompanion.insert(
              id: paymentId,
              businessId: _businessId,
              customerId: customerId,
              billId: Value(billId),
              amount: amount,
              method: method.name,
              refNote: Value(refNote),
              receivedBy: receivedByMemberId,
              syncStatus: const Value('pending'),
            ),
          );

      // Keep the cached balance consistent offline; the server-side balance
      // view overwrites it on the next pull.
      await _db.customStatement(
        'UPDATE local_customers SET balance_due = balance_due - ? WHERE id = ?',
        [amount, customerId],
      );

      if (enqueueRemote) {
        await _db.enqueue(
          entityType: 'payment',
          entityId: paymentId,
          dependsOnId: billId,
          payload: {
            'id': paymentId,
            'customer_id': customerId,
            'bill_id': billId,
            'amount': amount,
            'method': method.name,
            'ref_note': refNote,
            'received_by': receivedByMemberId,
          },
        );
      }
    });

    if (enqueueRemote) {
      unawaited(_sync.syncNow());
    }
    return mapLocalPayment(
      await (_db.select(
        _db.localPayments,
      )..where((p) => p.id.equals(paymentId))).getSingle(),
    );
  }

  @override
  Future<int> totalDues() async {
    final rows = await _db.select(_db.localCustomers).get();
    return rows.fold<int>(
      0,
      (sum, c) => sum + (c.balanceDue > 0 ? c.balanceDue : 0),
    );
  }
}
