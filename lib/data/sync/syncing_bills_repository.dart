import 'dart:async';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

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
  })  : _db = db,
        _sync = sync,
        _payments = payments,
        _businessId = businessId;

  final AppDatabase _db;
  final SyncService _sync;
  final PaymentsRepository _payments;
  final String _businessId;
  static const _uuid = Uuid();

  @override
  Future<List<Bill>> list({int offset = 0, int? limit}) async {
    final bills = await _db.select(_db.localBills).get();
    bills.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final sliced = limit == null ? bills : bills.skip(offset).take(limit).toList();
    final result = <Bill>[];
    for (final bill in sliced) {
      final items = await (_db.select(_db.localBillItems)
            ..where((i) => i.billId.equals(bill.id)))
          .get();
      result.add(mapLocalBill(bill, items));
    }
    return result;
  }

  @override
  Future<Bill> get(String id) async {
    final bill = await (_db.select(_db.localBills)
          ..where((b) => b.id.equals(id)))
        .getSingle();
    final items = await (_db.select(_db.localBillItems)
          ..where((i) => i.billId.equals(id)))
        .get();
    return mapLocalBill(bill, items);
  }

  @override
  Future<int> todaysSales() async {
    final now = DateTime.now().toUtc();
    final start = DateTime.utc(now.year, now.month, now.day);
    final bills = await _db.select(_db.localBills).get();
    return bills
        .where((b) => !b.createdAt.isBefore(start))
        .fold<int>(0, (sum, b) => sum + b.grandTotal);
  }

  @override
  Future<int> todaysBillCount() async {
    final now = DateTime.now().toUtc();
    final start = DateTime.utc(now.year, now.month, now.day);
    final bills = await _db.select(_db.localBills).get();
    return bills.where((b) => !b.createdAt.isBefore(start)).length;
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
      final customer = await (_db.select(_db.localCustomers)
            ..where((c) => c.id.equals(customerId)))
          .getSingleOrNull();
      shopName = customer?.shopName;
    }

    await _db.into(_db.localBills).insert(
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
      await _db.into(_db.localBillItems).insert(
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
        'id': itemId,
        'bill_id': billId,
        'product_id': line.productId,
        'name_snapshot': line.nameSnapshot,
        'qty': line.qty,
        'rate': line.rate,
        'discount': line.discount,
        'line_total': line.lineTotal,
      });
    }

    await _db.enqueue(
      entityType: 'bill',
      entityId: billId,
      payload: {
        'id': billId,
        'customer_id': customerId,
        'items_total': itemsTotal,
        'discount': discount,
        'grand_total': grandTotal,
        'status': status.name,
        'created_by': createdByMemberId,
        'device_prefix': meta.devicePrefix,
      },
    );

    if (itemRows.isNotEmpty) {
      await _db.enqueue(
        entityType: 'bill_items',
        entityId: billId,
        dependsOnId: billId,
        payload: {'items': itemRows},
      );
    }

    if (customerId != null &&
        (status == BillStatus.paid || status == BillStatus.partial)) {
      final amount =
          status == BillStatus.paid ? grandTotal : (paymentAmount ?? 0);
      if (amount > 0) {
        await _payments.record(
          customerId: customerId,
          amount: amount,
          method: paymentMethod,
          refNote: paymentRefNote,
          billId: billId,
          receivedByMemberId: createdByMemberId,
        );
      }
    }

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
