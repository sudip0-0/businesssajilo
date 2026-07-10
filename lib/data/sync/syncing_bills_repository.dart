import 'dart:async';

import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/report_range.dart';
import '../../domain/enums.dart';
import '../../domain/models/bill.dart';
import '../local/app_database.dart';
import '../local/local_mappers.dart';
import '../repositories/bills_repository.dart';
import '../repositories/payments_repository.dart';
import 'sync_service.dart';

class SyncingBillsRepository implements BillsRepository {
  SyncingBillsRepository({
    required AppDatabase db,
    required SyncService sync,
    required PaymentsRepository payments,
    required String businessId,
    SupabaseClient? client,
  }) : _db = db,
       _sync = sync,
       _payments = payments,
       _businessId = businessId,
       _client = client;

  final AppDatabase _db;
  final SyncService _sync;
  final PaymentsRepository _payments;
  final String _businessId;
  final SupabaseClient? _client;
  static const _uuid = Uuid();

  @override
  Future<List<Bill>> list({int offset = 0, int? limit}) async {
    final query = _db.select(_db.localBills)
      ..orderBy([(b) => OrderingTerm.desc(b.createdAt)]);
    if (limit != null) {
      query.limit(limit, offset: offset);
    }
    final bills = await query.get();
    return _attachItems(bills);
  }

  Future<List<Bill>> _attachItems(List<LocalBill> bills) async {
    if (bills.isEmpty) return const [];
    final ids = bills.map((b) => b.id).toList();
    final items = await (_db.select(
      _db.localBillItems,
    )..where((i) => i.billId.isIn(ids))).get();
    final byBill = <String, List<LocalBillItem>>{};
    for (final item in items) {
      (byBill[item.billId] ??= []).add(item);
    }
    return [
      for (final bill in bills) mapLocalBill(bill, byBill[bill.id] ?? const []),
    ];
  }

  @override
  Future<Bill> get(String id) async {
    final bill = await (_db.select(
      _db.localBills,
    )..where((b) => b.id.equals(id))).getSingle();
    final items = await (_db.select(
      _db.localBillItems,
    )..where((i) => i.billId.equals(id))).get();
    return mapLocalBill(bill, items);
  }

  @override
  Future<int> todaysSales() async {
    final net = await _netSalesFromReport(nptDayStartUtc());
    if (net != null) return net;
    // Offline fallback: local bills only (credit notes are online-only).
    final start = nptDayStartUtc();
    final rows = await (_db.select(
      _db.localBills,
    )..where((b) => b.createdAt.isBiggerOrEqualValue(start))).get();
    return rows.fold<int>(0, (sum, b) => sum + b.grandTotal);
  }

  @override
  Future<int> todaysBillCount() async {
    final start = nptDayStartUtc();
    final count = _db.localBills.id.count();
    final query = _db.selectOnly(_db.localBills)
      ..addColumns([count])
      ..where(_db.localBills.createdAt.isBiggerOrEqualValue(start));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  @override
  Future<int> yesterdaysSales() async {
    final yesterdayStart = nptDayStartUtc().subtract(const Duration(days: 1));
    final net = await _netSalesFromReport(yesterdayStart);
    if (net != null) return net;
    final todayStart = nptDayStartUtc();
    final rows =
        await (_db.select(_db.localBills)..where(
              (b) =>
                  b.createdAt.isBiggerOrEqualValue(yesterdayStart) &
                  b.createdAt.isSmallerThanValue(todayStart),
            ))
            .get();
    return rows.fold<int>(0, (sum, b) => sum + b.grandTotal);
  }

  /// Prefer report_sales_daily (nets credit notes) when online.
  Future<int?> _netSalesFromReport(DateTime dayStartUtc) async {
    final client = _client;
    if (client == null) return null;
    try {
      final day = nptDateString(dayStartUtc);
      final rows = await client
          .from('report_sales_daily')
          .select('total_sales')
          .eq('sale_date', day);
      var total = 0;
      for (final row in rows as List) {
        total += ((row as Map)['total_sales'] as num?)?.toInt() ?? 0;
      }
      return total;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Bill>> listTodaysBills({int limit = 20}) async {
    final start = nptDayStartUtc();
    final bills =
        await (_db.select(_db.localBills)
              ..where((b) => b.createdAt.isBiggerOrEqualValue(start))
              ..orderBy([(b) => OrderingTerm.desc(b.createdAt)])
              ..limit(limit))
            .get();
    return _attachItems(bills);
  }

  @override
  Future<List<Bill>> search(String query, {int limit = 50}) async {
    final q = query.trim();
    if (q.isEmpty) return list(limit: limit);
    final pattern = '%$q%';
    final bills =
        await (_db.select(_db.localBills)
              ..where((b) => b.billNo.like(pattern))
              ..orderBy([(b) => OrderingTerm.desc(b.createdAt)])
              ..limit(limit))
            .get();
    return _attachItems(bills);
  }

  @override
  Future<Bill> create({
    required String createdByMemberId,
    String? customerId,
    required BillStatus status,
    required int itemsTotal,
    required int discount,
    required int grandTotal,
    required List<BillLineInput> lines,
    PaymentMethod paymentMethod = PaymentMethod.cash,
    String? paymentRefNote,
    int? paymentAmount,
  }) async {
    final billId = _uuid.v4();
    final meta = await _db.select(_db.deviceMeta).getSingle();
    final provisionalNo = await _db.nextProvisionalBillNo();
    String? shopName;
    if (customerId != null) {
      final customer = await (_db.select(
        _db.localCustomers,
      )..where((c) => c.id.equals(customerId))).getSingleOrNull();
      shopName = customer?.shopName;
    }

    await _db.transaction(() async {
      await _db
          .into(_db.localBills)
          .insert(
            LocalBillsCompanion.insert(
              id: billId,
              businessId: _businessId,
              customerId: Value(customerId),
              billNo: provisionalNo,
              provisionalBillNo: Value(provisionalNo),
              devicePrefix: Value(meta.devicePrefix),
              itemsTotal: Value(itemsTotal),
              discount: Value(discount),
              grandTotal: Value(grandTotal),
              status: status.name,
              createdBy: createdByMemberId,
              customerShopName: Value(shopName),
              syncStatus: const Value('pending'),
            ),
          );

      final itemRows = <Map<String, dynamic>>[];
      for (final line in lines) {
        final itemId = _uuid.v4();
        await _db
            .into(_db.localBillItems)
            .insert(
              LocalBillItemsCompanion.insert(
                id: itemId,
                billId: billId,
                productId: line.productId,
                nameSnapshot: line.nameSnapshot,
                qty: line.qty,
                rate: Value(line.rate),
                discount: Value(line.discount),
                lineTotal: Value(line.lineTotal),
              ),
            );
        itemRows.add({
          'product_id': line.productId,
          'name_snapshot': line.nameSnapshot,
          'qty': line.qty,
          'rate': line.rate,
          'discount': line.discount,
        });
      }

      // Customer bills debit the local balance; payments (below) credit it.
      if (customerId != null) {
        await _db.customStatement(
          'UPDATE local_customers SET balance_due = balance_due + ? WHERE id = ?',
          [grandTotal, customerId],
        );
      }

      // Embed payment in the bill payload so create_bill inserts bill + payment
      // atomically (avoids paid-without-payment if payment sync fails separately).
      Map<String, dynamic>? paymentPayload;
      if (customerId != null &&
          (status == BillStatus.paid || status == BillStatus.partial)) {
        final amount = status == BillStatus.paid
            ? grandTotal
            : (paymentAmount ?? 0);
        if (amount > 0) {
          final paymentId = _uuid.v4();
          paymentPayload = {
            'id': paymentId,
            'amount': amount,
            'method': paymentMethod.name,
            'ref_note': paymentRefNote,
          };
          // Local row for offline balance/UI; remote insert is via create_bill.
          await _payments.record(
            id: paymentId,
            customerId: customerId,
            amount: amount,
            method: paymentMethod,
            refNote: paymentRefNote,
            billId: billId,
            receivedByMemberId: createdByMemberId,
            enqueueRemote: false,
          );
        }
      }

      await _db.enqueue(
        entityType: 'bill',
        entityId: billId,
        payload: {
          'id': billId,
          'customer_id': customerId,
          'order_id': null,
          'discount': discount,
          'status': status.name,
          'device_prefix': meta.devicePrefix,
          'items': itemRows,
          'payment': ?paymentPayload,
        },
      );
    });

    unawaited(_sync.syncNow());
    return get(billId);
  }

  @override
  Future<Bill> createFromOrder({
    required String orderId,
    required String customerId,
    required String createdByMemberId,
    required BillStatus status,
    required int itemsTotal,
    required int discount,
    required int grandTotal,
    required List<BillLineInput> lines,
    PaymentMethod paymentMethod = PaymentMethod.cash,
    String? paymentRefNote,
    int? paymentAmount,
  }) {
    throw UnsupportedError('Order billing requires connectivity');
  }
}
