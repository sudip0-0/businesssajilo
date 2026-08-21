import 'dart:async';

import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/bill_search_match.dart';
import '../../core/utils/report_range.dart';
import '../../domain/enums.dart';
import '../../domain/models/bill.dart';
import '../local/app_database.dart';
import '../local/local_mappers.dart';
import '../remote/supabase_bills_repository.dart';
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
  Future<List<Bill>> list({
    int offset = 0,
    int? limit,
    BillStatus? status,
  }) async {
    final query = _db.select(_db.localBills)
      ..orderBy([(b) => OrderingTerm.desc(b.createdAt)]);
    if (status != null) {
      query.where((b) => b.status.equals(status.name));
    }
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
    // Offline fallback: confirmed local bills only. Pending/failed totals are
    // exposed separately via [unsyncedTodaysSales] so they cannot be shown as
    // committed sales.
    return _todaysLocalSales(syncedOnly: true);
  }

  @override
  Future<int> unsyncedTodaysSales() async {
    return _todaysLocalSales(syncedOnly: false);
  }

  Future<int> _todaysLocalSales({required bool syncedOnly}) async {
    final start = nptDayStartUtc();
    final end = start.add(const Duration(days: 1));
    final rows =
        await (_db.select(_db.localBills)..where((b) {
              final inToday =
                  b.createdAt.isBiggerOrEqualValue(start) &
                  b.createdAt.isSmallerThanValue(end);
              if (syncedOnly) {
                return inToday & b.syncStatus.equals('synced');
              }
              return inToday &
                  (b.syncStatus.equals('pending') |
                      b.syncStatus.equals('failed'));
            }))
            .get();
    return rows.fold<int>(0, (sum, b) => sum + b.grandTotal);
  }

  @override
  Future<int> todaysBillCount() async {
    final start = nptDayStartUtc();
    final end = start.add(const Duration(days: 1));
    final count = _db.localBills.id.count();
    final query = _db.selectOnly(_db.localBills)
      ..addColumns([count])
      ..where(
        _db.localBills.createdAt.isBiggerOrEqualValue(start) &
            _db.localBills.createdAt.isSmallerThanValue(end),
      );
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
          .eq('sale_date', day)
          .then((value) => value)
          .timeout(const Duration(seconds: 3));
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
    final end = start.add(const Duration(days: 1));
    final bills =
        await (_db.select(_db.localBills)
              ..where(
                (b) =>
                    b.createdAt.isBiggerOrEqualValue(start) &
                    b.createdAt.isSmallerThanValue(end),
              )
              ..orderBy([(b) => OrderingTerm.desc(b.createdAt)])
              ..limit(limit))
            .get();
    return _attachItems(bills);
  }

  @override
  Future<List<Bill>> listOpenForCustomer(String customerId) async {
    final rows =
        await (_db.select(_db.localBills)
              ..where(
                (b) =>
                    b.customerId.equals(customerId) &
                    b.status.isIn(['due', 'partial']),
              )
              ..orderBy([(b) => OrderingTerm.asc(b.createdAt)]))
            .get();
    return _attachItems(rows);
  }

  @override
  Future<List<Bill>> search(
    String query, {
    int limit = 50,
    int offset = 0,
    BillStatus? status,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return list(limit: limit);

    final pattern = '%$q%';
    final amountPaisa = billSearchAmountPaisa(q);
    const candidateLimit = 200;

    final textQuery = _db.select(_db.localBills)
      ..where((b) {
        final textMatch =
            b.billNo.like(pattern) |
            (b.customerShopName.isNotNull() & b.customerShopName.like(pattern));
        if (amountPaisa != null) {
          return textMatch | b.grandTotal.equals(amountPaisa);
        }
        return textMatch;
      })
      ..orderBy([(b) => OrderingTerm.desc(b.createdAt)])
      ..limit(candidateLimit);

    // Recent window so free-text dates (e.g. "11 Aug") can match without SQL.
    final recentQuery = _db.select(_db.localBills)
      ..orderBy([(b) => OrderingTerm.desc(b.createdAt)])
      ..limit(candidateLimit);

    final textHits = await textQuery.get();
    final recent = await recentQuery.get();
    final byId = <String, LocalBill>{
      for (final bill in textHits) bill.id: bill,
      for (final bill in recent) bill.id: bill,
    };
    final candidates = byId.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final matched = <LocalBill>[];
    for (final row in candidates) {
      if (billMatchesSearchFields(
        billNo: row.billNo,
        customerShopName: row.customerShopName,
        grandTotal: row.grandTotal,
        createdAt: row.createdAt,
        query: q,
      )) {
        matched.add(row);
        if (matched.length >= limit) break;
      }
    }
    return _attachItems(matched);
  }

  /// Reports always prefer remote (same as customer ledger). Falls back to
  /// local bills when offline / no client.
  @override
  Future<List<Bill>> listInRange({
    required DateTime from,
    required DateTime to,
    String? query,
    int offset = 0,
    int? limit,
    BillStatus? status,
  }) async {
    final client = _client;
    if (client != null) {
      try {
        return await SupabaseBillsRepository(client, _payments).listInRange(
          from: from,
          to: to,
          query: query,
          offset: offset,
          limit: limit,
          status: status,
        );
      } catch (_) {
        // Fall through to local.
      }
    }

    final fromUtc = from.toUtc();
    final toUtc = to.toUtc();
    final q = query?.trim();
    final pattern = (q != null && q.isNotEmpty) ? '%$q%' : null;
    final request = _db.select(_db.localBills)
      ..where((b) {
        final inRange =
            b.createdAt.isBiggerOrEqualValue(fromUtc) &
            b.createdAt.isSmallerThanValue(toUtc);
        if (pattern == null) return inRange;
        final shopMatch =
            b.customerShopName.isNotNull() & b.customerShopName.like(pattern);
        return inRange & (b.billNo.like(pattern) | shopMatch);
      })
      ..orderBy([(b) => OrderingTerm.desc(b.createdAt)]);
    if (limit != null) {
      request.limit(limit, offset: offset);
    }
    final bills = await request.get();
    return _attachItems(bills);
  }

  @override
  Future<Bill> create({
    required String createdByMemberId,
    String? customerId,
    String? guestName,
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
    String? customerPhone;
    if (customerId != null) {
      final customer = await (_db.select(
        _db.localCustomers,
      )..where((c) => c.id.equals(customerId))).getSingleOrNull();
      shopName = customer?.shopName;
      customerPhone = customer?.phone;
    } else {
      final trimmed = guestName?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        shopName = trimmed;
      }
    }

    final createdAt = DateTime.now().toUtc();
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
              createdAt: Value(createdAt),
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
        // Mirror server counter-sale stock deduction locally so offline UI
        // stays honest until pull adopts the server value. Negative stock is
        // allowed (alert-only policy); amount-only lines have empty productId.
        if (line.productId.isNotEmpty) {
          await _decrementLocalStock(line.productId, line.qty);
          await _db
              .into(_db.localStockMovements)
              .insert(
                LocalStockMovementsCompanion.insert(
                  id: _uuid.v4(),
                  businessId: _businessId,
                  productId: line.productId,
                  type: 'dispatch',
                  qtyDelta: -line.qty,
                  reason: Value('Counter sale $provisionalNo'),
                  refBillId: Value(billId),
                  createdBy: createdByMemberId,
                  createdAt: Value(createdAt),
                ),
              );
        }
        itemRows.add({
          'product_id': line.productId.isEmpty ? null : line.productId,
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
          'created_at': createdAt.toIso8601String(),
          if (customerId == null && shopName != null) 'guest_name': shopName,
          if (customerId != null && shopName != null && shopName.isNotEmpty)
            'customer_shop_name': shopName,
          if (customerId != null &&
              customerPhone != null &&
              customerPhone.isNotEmpty)
            'customer_phone': customerPhone,
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

  @override
  Future<Bill> recordAmountSale({
    required String customerId,
    required String createdByMemberId,
    required int amountPaisa,
    String? refNote,
    bool paidNow = false,
    PaymentMethod paymentMethod = PaymentMethod.cash,
  }) async {
    final billId = _uuid.v4();
    final meta = await _db.select(_db.deviceMeta).getSingle();
    final provisionalNo = await _db.nextProvisionalBillNo();
    final customer = await (_db.select(
      _db.localCustomers,
    )..where((c) => c.id.equals(customerId))).getSingleOrNull();
    final shopName = customer?.shopName;
    final status = paidNow ? BillStatus.paid : BillStatus.due;
    final note = refNote?.trim();
    final nameSnapshot = (note == null || note.isEmpty) ? 'Manual sale' : note;

    final createdAt = DateTime.now().toUtc();
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
              itemsTotal: Value(amountPaisa),
              discount: const Value(0),
              grandTotal: Value(amountPaisa),
              status: status.name,
              createdBy: createdByMemberId,
              customerShopName: Value(shopName),
              syncStatus: const Value('pending'),
              createdAt: Value(createdAt),
            ),
          );

      await _db
          .into(_db.localBillItems)
          .insert(
            LocalBillItemsCompanion.insert(
              id: _uuid.v4(),
              billId: billId,
              productId: '',
              nameSnapshot: nameSnapshot,
              qty: 1,
              rate: Value(amountPaisa),
              discount: const Value(0),
              lineTotal: Value(amountPaisa),
            ),
          );

      await _db.customStatement(
        'UPDATE local_customers SET balance_due = balance_due + ? WHERE id = ?',
        [amountPaisa, customerId],
      );

      Map<String, dynamic>? paymentPayload;
      if (paidNow) {
        final paymentId = _uuid.v4();
        paymentPayload = {
          'id': paymentId,
          'amount': amountPaisa,
          'method': paymentMethod.name,
          'ref_note': note,
        };
        await _payments.record(
          id: paymentId,
          customerId: customerId,
          amount: amountPaisa,
          method: paymentMethod,
          refNote: note,
          billId: billId,
          receivedByMemberId: createdByMemberId,
          enqueueRemote: false,
        );
      }

      await _db.enqueue(
        entityType: 'bill',
        entityId: billId,
        payload: {
          'id': billId,
          'manual_sale': true,
          'customer_id': customerId,
          'amount': amountPaisa,
          'ref_note': note,
          'device_prefix': meta.devicePrefix,
          'created_at': createdAt.toIso8601String(),
          'customer_shop_name': ?shopName,
          'customer_phone': ?customer?.phone,
          'payment': ?paymentPayload,
        },
      );
    });

    unawaited(_sync.syncNow());
    return get(billId);
  }

  /// Decrements [LocalProducts.stockCached] by [qty]. Negative results are
  /// allowed — matches the server alert-only negative-stock policy.
  Future<void> _decrementLocalStock(String productId, int qty) async {
    final product = await (_db.select(
      _db.localProducts,
    )..where((p) => p.id.equals(productId))).getSingleOrNull();
    if (product == null) return;
    await (_db.update(
      _db.localProducts,
    )..where((p) => p.id.equals(productId))).write(
      LocalProductsCompanion(stockCached: Value(product.stockCached - qty)),
    );
  }
}
