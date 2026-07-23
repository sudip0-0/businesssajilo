import 'package:businesssajilo/data/local/app_database.dart';
import 'package:businesssajilo/data/remote/supabase_products_repository.dart';
import 'package:businesssajilo/data/repositories/payments_repository.dart';
import 'package:businesssajilo/data/sync/cached_customers_repository.dart';
import 'package:businesssajilo/data/sync/cached_products_repository.dart';
import 'package:businesssajilo/data/sync/sync_service.dart';
import 'package:businesssajilo/data/sync/syncing_bills_repository.dart';
import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/domain/models/payment.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakePaymentsRepository implements PaymentsRepository {
  @override
  Future<List<Payment>> listByCustomer(
    String customerId, {
    int offset = 0,
    int limit = 50,
  }) async => const [];

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
  }) {
    throw UnimplementedError();
  }

  @override
  Future<int> totalDues() async => 0;
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedBills() async {
    final now = DateTime.utc(2026, 7, 9, 10);
    for (var i = 0; i < 5; i++) {
      final billId = 'bill-$i';
      await db
          .into(db.localBills)
          .insert(
            LocalBillsCompanion.insert(
              id: billId,
              businessId: 'biz',
              billNo: 'B-$i',
              status: 'paid',
              createdBy: 'member',
              grandTotal: Value(1000 * (i + 1)),
              createdAt: Value(now.subtract(Duration(hours: i))),
            ),
          );
      await db
          .into(db.localBillItems)
          .insert(
            LocalBillItemsCompanion.insert(
              id: 'item-$i-a',
              billId: billId,
              productId: 'prod',
              nameSnapshot: 'Item A',
              qty: 1,
              lineTotal: const Value(500),
            ),
          );
      await db
          .into(db.localBillItems)
          .insert(
            LocalBillItemsCompanion.insert(
              id: 'item-$i-b',
              billId: billId,
              productId: 'prod',
              nameSnapshot: 'Item B',
              qty: 1,
              lineTotal: const Value(500),
            ),
          );
    }
  }

  SyncingBillsRepository billsRepo() {
    // SyncService needs a real SupabaseClient; list/search never call it.
    final sync = SyncService(
      db: db,
      client: SupabaseClient('http://localhost', 'anon'),
    );
    return SyncingBillsRepository(
      db: db,
      sync: sync,
      payments: _FakePaymentsRepository(),
      businessId: 'biz',
    );
  }

  test('bill list uses limit/offset and batch-loads items', () async {
    await seedBills();
    final repo = billsRepo();

    final page = await repo.list(offset: 0, limit: 2);
    expect(page, hasLength(2));
    expect(page.map((b) => b.billNo).toList(), ['B-0', 'B-1']);
    expect(page.every((b) => b.items.length == 2), isTrue);

    final page2 = await repo.list(offset: 2, limit: 2);
    expect(page2.map((b) => b.billNo).toList(), ['B-2', 'B-3']);
  });

  test('bill search filters by bill_no without loading all bills', () async {
    await seedBills();
    final repo = billsRepo();
    final hits = await repo.search('B-3', limit: 10);
    expect(hits, hasLength(1));
    expect(hits.single.billNo, 'B-3');
    expect(hits.single.items, hasLength(2));
  });

  test('product list paginates in SQL order by name', () async {
    final now = DateTime.utc(2026, 1, 1);
    for (final name in ['Zebra', 'Apple', 'Mango', 'Banana']) {
      await db
          .into(db.localProducts)
          .insert(
            LocalProductsCompanion.insert(
              id: name.toLowerCase(),
              businessId: 'biz',
              name: name,
              unit: 'pcs',
              updatedAt: now,
            ),
          );
    }
    final repo = CachedProductsRepository(
      db: db,
      remote: SupabaseProductsRepository(null),
    );
    final page = await repo.list(offset: 1, limit: 2);
    expect(page.map((p) => p.name).toList(), ['Banana', 'Mango']);
  });

  test('lowStockCount uses SQL comparison', () async {
    final now = DateTime.utc(2026, 1, 1);
    await db
        .into(db.localProducts)
        .insert(
          LocalProductsCompanion.insert(
            id: 'low',
            businessId: 'biz',
            name: 'Low',
            unit: 'pcs',
            lowStockThreshold: const Value(5),
            stockCached: const Value(1),
            updatedAt: now,
          ),
        );
    await db
        .into(db.localProducts)
        .insert(
          LocalProductsCompanion.insert(
            id: 'ok',
            businessId: 'biz',
            name: 'Ok',
            unit: 'pcs',
            lowStockThreshold: const Value(5),
            stockCached: const Value(20),
            updatedAt: now,
          ),
        );
    final repo = CachedProductsRepository(
      db: db,
      remote: SupabaseProductsRepository(null),
    );
    expect(await repo.lowStockCount(), 1);
  });

  test('customer list paginates by shop name', () async {
    final now = DateTime.utc(2026, 1, 1);
    for (final name in ['Z Shop', 'A Shop', 'M Shop']) {
      await db
          .into(db.localCustomers)
          .insert(
            LocalCustomersCompanion.insert(
              id: name,
              businessId: 'biz',
              memberId: 'm',
              shopName: name,
              updatedAt: now,
              createdAt: Value(now),
            ),
          );
    }
    final repo = CachedCustomersRepository(db: db, client: null);
    final page = await repo.list(offset: 0, limit: 2);
    expect(page.map((c) => c.shopName).toList(), ['A Shop', 'M Shop']);
  });
}
