import 'package:businesssajilo/core/utils/report_range.dart';
import 'package:businesssajilo/data/local/app_database.dart';
import 'package:businesssajilo/data/repositories/payments_repository.dart';
import 'package:businesssajilo/data/sync/sync_service.dart';
import 'package:businesssajilo/data/sync/syncing_bills_repository.dart';
import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/domain/models/owner_dashboard_stats.dart';
import 'package:businesssajilo/domain/models/payment.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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
    String? allocate,
    required String receivedByMemberId,
    bool enqueueRemote = true,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<int> totalDues() async => 0;

  @override
  Future<int> totalReceivedForBill(String billId) async => 0;
}

void main() {
  late AppDatabase db;
  late SyncingBillsRepository bills;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    bills = SyncingBillsRepository(
      db: db,
      sync: SyncService(
        db: db,
        client: SupabaseClient('http://localhost', 'anon'),
        connectivityCheck: () async => const [ConnectivityResult.none],
        reachabilityProbe: () async => false,
      ),
      payments: _FakePaymentsRepository(),
      businessId: 'biz',
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> insertBill({
    required String id,
    required int total,
    required String syncStatus,
  }) {
    final start = nptDayStartUtc();
    return db
        .into(db.localBills)
        .insert(
          LocalBillsCompanion.insert(
            id: id,
            businessId: 'biz',
            billNo: id,
            grandTotal: Value(total),
            status: 'paid',
            createdBy: 'member-1',
            syncStatus: Value(syncStatus),
            createdAt: Value(start.add(const Duration(hours: 1))),
          ),
        );
  }

  test('confirmed sales and pending bills are tracked separately', () async {
    await insertBill(id: 'synced', total: 1000, syncStatus: 'synced');
    await insertBill(id: 'pending', total: 400, syncStatus: 'pending');

    expect(await bills.todaysSales(), 1000);
    expect(await bills.unsyncedTodaysSales(), 400);
    const stats = OwnerDashboardStats(
      todaySales: 1000,
      yesterdaySales: 0,
      totalDues: 0,
      lowStockCount: 0,
      pendingOrders: 0,
      pendingSyncSales: 400,
    );
    expect(stats.todaySales, 1000);
    expect(stats.pendingSyncSales, 400);
    expect(stats.todaySales! + stats.pendingSyncSales, 1400);
  });

  test('failed bills never inflate confirmed sales', () async {
    await insertBill(id: 'synced', total: 700, syncStatus: 'synced');
    await insertBill(id: 'failed', total: 900, syncStatus: 'failed');

    expect(await bills.todaysSales(), 700);
    expect(await bills.unsyncedTodaysSales(), 900);
  });

  test(
    'a newly synced bill moves from pending to confirmed without changing the combined total',
    () async {
      await insertBill(id: 'keep', total: 1000, syncStatus: 'synced');
      await insertBill(id: 'moving', total: 500, syncStatus: 'pending');

      final beforeConfirmed = await bills.todaysSales();
      final beforePending = await bills.unsyncedTodaysSales();
      expect(beforeConfirmed + beforePending, 1500);

      await (db.update(db.localBills)..where((b) => b.id.equals('moving')))
          .write(const LocalBillsCompanion(syncStatus: Value('synced')));

      final afterConfirmed = await bills.todaysSales();
      final afterPending = await bills.unsyncedTodaysSales();
      expect(afterConfirmed, 1500);
      expect(afterPending, 0);
      expect(afterConfirmed + afterPending, beforeConfirmed + beforePending);
    },
  );
}
