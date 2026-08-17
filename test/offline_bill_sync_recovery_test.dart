import 'dart:convert';

import 'package:businesssajilo/data/local/app_database.dart';
import 'package:businesssajilo/data/repositories/bills_repository.dart';
import 'package:businesssajilo/data/repositories/payments_repository.dart';
import 'package:businesssajilo/data/sync/sync_pusher.dart';
import 'package:businesssajilo/data/sync/sync_service.dart';
import 'package:businesssajilo/data/sync/syncing_bills_repository.dart';
import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/domain/models/payment.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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

http.Response _json(http.BaseRequest request, Object body, {int status = 200}) {
  return http.Response(
    body is String ? body : jsonEncode(body),
    status,
    headers: const {'content-type': 'application/json'},
    request: request,
  );
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'stale customer bill remaps on push and marks the queue row synced',
    () async {
      await db.ensureDeviceMeta('device-1');
      await db
          .into(db.localCustomers)
          .insert(
            LocalCustomersCompanion.insert(
              id: 'c0c0c0c0-c0c0-4000-8000-c0c0c0c0c0c0',
              businessId: 'biz',
              memberId: 'm-stale',
              shopName: 'Ram Store',
              phone: const Value('+9779811111111'),
              balanceDue: const Value(0),
              updatedAt: DateTime.utc(2026, 8, 1),
            ),
          );
      await db
          .into(db.localCustomers)
          .insert(
            LocalCustomersCompanion.insert(
              id: 'e1111111-1111-1111-1111-111111111111',
              businessId: 'biz',
              memberId: 'm-live',
              shopName: 'Ram Store',
              phone: const Value('+9779811111111'),
              balanceDue: const Value(0),
              updatedAt: DateTime.utc(2026, 8, 1),
            ),
          );

      Map<String, dynamic>? posted;
      final client = SupabaseClient(
        'http://localhost',
        'anon-key',
        httpClient: MockClient((request) async {
          posted = jsonDecode(request.body) as Map<String, dynamic>;
          return _json(request, {
            'bill': {
              'id': posted?['p']?['id'],
              'bill_no': 'BS-0042',
              'status': 'due',
              'customer_id': 'e1111111-1111-1111-1111-111111111111',
            },
            'created': true,
          });
        }),
      );

      final sync = SyncService(
        db: db,
        client: client,
        connectivityCheck: () async => const [ConnectivityResult.none],
        reachabilityProbe: () async => false,
      );
      final repo = SyncingBillsRepository(
        db: db,
        sync: sync,
        payments: _FakePaymentsRepository(),
        businessId: 'biz',
        client: client,
      );

      final bill = await repo.create(
        createdByMemberId: 'member-1',
        customerId: 'c0c0c0c0-c0c0-4000-8000-c0c0c0c0c0c0',
        status: BillStatus.due,
        itemsTotal: 1500,
        discount: 0,
        grandTotal: 1500,
        lines: const [
          BillLineInput(
            productId: 'prod-1',
            nameSnapshot: 'Cola',
            qty: 1,
            rate: 1500,
            lineTotal: 1500,
          ),
        ],
      );

      final queued = await db.pendingQueue();
      expect(queued, hasLength(1));
      final payload =
          jsonDecode(queued.single.payloadJson) as Map<String, dynamic>;
      expect(payload['id'], bill.id);
      expect(payload['customer_shop_name'], 'Ram Store');
      expect(payload['customer_phone'], '+9779811111111');
      expect(payload['created_at'], isNotEmpty);

      final staleBefore =
          await (db.select(db.localCustomers)..where(
                (c) => c.id.equals('c0c0c0c0-c0c0-4000-8000-c0c0c0c0c0c0'),
              ))
              .getSingle();
      expect(staleBefore.balanceDue, 1500);

      expect(await SyncPusher(db: db, client: client).push(), 1);

      final p = posted?['p'] as Map<String, dynamic>?;
      expect(p?['id'], bill.id);
      expect(p?['customer_shop_name'], 'Ram Store');
      expect(p?['customer_phone'], '+9779811111111');
      expect(p?['created_at'], isNotEmpty);

      final local = await repo.get(bill.id);
      expect(local.pendingSync, isFalse);
      expect(local.billNo, 'BS-0042');
      expect(local.customerId, 'e1111111-1111-1111-1111-111111111111');

      expect(await db.pendingQueue(), isEmpty);
      expect(await db.failedCount(), 0);
      final remaining = await db.unsyncedQueue();
      expect(remaining.where((r) => r.status != 'synced'), isEmpty);

      final staleAfter =
          await (db.select(db.localCustomers)..where(
                (c) => c.id.equals('c0c0c0c0-c0c0-4000-8000-c0c0c0c0c0c0'),
              ))
              .getSingle();
      final liveAfter =
          await (db.select(db.localCustomers)..where(
                (c) => c.id.equals('e1111111-1111-1111-1111-111111111111'),
              ))
              .getSingle();
      expect(staleAfter.balanceDue, 0);
      expect(liveAfter.balanceDue, 1500);
    },
  );
}
