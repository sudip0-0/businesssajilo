import 'dart:async';
import 'dart:convert';

import 'package:businesssajilo/data/sync/sync_constants.dart';
import 'package:businesssajilo/data/sync/sync_pusher.dart';
import 'package:businesssajilo/data/sync/pull/sync_pull_entities.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:businesssajilo/data/local/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Map<String, dynamic> _paymentRow({
  String id = 'root',
  int amount = 5000,
  String? billId,
}) => {
  'id': id,
  'business_id': 'business',
  'customer_id': 'customer',
  'amount': amount,
  'method': 'cash',
  'bill_id': billId,
  'received_by': 'member',
  'created_at': '2026-01-01T00:00:00Z',
  'ref_note': null,
};

Future<void> _seedPayment(AppDatabase db, {String? allocate}) async {
  await db
      .into(db.localPayments)
      .insert(
        LocalPaymentsCompanion.insert(
          id: 'root',
          businessId: 'business',
          customerId: 'customer',
          amount: 5000,
          method: 'cash',
          receivedBy: 'member',
        ),
      );
  await db.enqueue(
    entityType: 'payment',
    entityId: 'root',
    payload: {
      'id': 'root',
      'customer_id': 'customer',
      'amount': 5000,
      'method': 'cash',
      'received_by': 'member',
      'allocate': allocate,
    },
  );
}

void main() {
  for (final allocate in [null, 'oldest_first']) {
    final replies = <Object?>[
      null,
      [],
      7,
      'invalid',
      {},
      {'payment': null},
      {'payment': []},
      {
        'payment': {..._paymentRow(), 'id': 'other'},
      },
      {
        'payment': {..._paymentRow(), 'customer_id': 'other'},
      },
      {
        'payment': {..._paymentRow()}..remove('customer_id'),
      },
      {
        'payment': {..._paymentRow()}..remove('amount'),
      },
      {
        'payment': {..._paymentRow(), 'amount': 0},
      },
      {
        'payment': {..._paymentRow(), 'amount': 0.5},
      },
      {
        'payment': {..._paymentRow(), 'amount': 5001},
      },
      {
        'payment': {..._paymentRow(), 'method': 'invalid'},
      },
      {
        'payment': {..._paymentRow(), 'bill_id': 42},
      },
      {
        'payment': {..._paymentRow(), 'created_at': 'invalid'},
      },
      {
        'payment': {..._paymentRow(), 'business_id': 'other'},
      },
      {
        'payment': {..._paymentRow(), 'received_by': 'other'},
      },
      if (allocate == null) {'payment': _paymentRow(amount: 1500)},
    ];
    for (var i = 0; i < replies.length; i++) {
      test(
        'payment malformed reply $i remains pending then retries ($allocate)',
        () async {
          final db = AppDatabase.forTesting(NativeDatabase.memory());
          addTearDown(db.close);
          await _seedPayment(db, allocate: allocate);
          Object? reply = replies[i];
          var requests = 0;
          final client = SupabaseClient(
            'http://localhost',
            'anon',
            httpClient: MockClient((request) async {
              requests++;
              expect((jsonDecode(request.body) as Map)['p']['id'], 'root');
              return http.Response(
                jsonEncode(reply),
                200,
                headers: {'content-type': 'application/json'},
                request: request,
              );
            }),
          );
          addTearDown(client.dispose);
          final pusher = SyncPusher(db: db, client: client);
          expect(await pusher.push(), 0);
          expect(requests, 1);
          expect(
            (await db.select(db.localPayments).getSingle()).syncStatus,
            'pending',
          );
          expect((await db.select(db.localPayments).getSingle()).amount, 5000);
          expect((await db.pendingQueue()).single.attempts, 1);
          reply = {
            'payment': _paymentRow(
              amount: allocate == null ? 5000 : 1500,
              billId: allocate == null ? null : 'allocated-bill',
            ),
            'created': false,
          };
          await db
              .update(db.syncQueue)
              .write(const SyncQueueCompanion(nextAttemptAt: Value(null)));
          expect(await pusher.push(), 1);
          expect(requests, 2);
          final local = await db.select(db.localPayments).getSingle();
          expect(local.syncStatus, 'synced');
          expect(local.amount, allocate == null ? 5000 : 1500);
          expect(local.billId, allocate == null ? null : 'allocated-bill');
          expect(await db.pendingQueue(), isEmpty);
        },
      );
    }
  }

  test(
    'split replay corrects root skipped by prior pull and repulls allocation window',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await _seedPayment(db, allocate: 'oldest_first');
      await db
          .into(db.localCustomers)
          .insert(
            LocalCustomersCompanion.insert(
              id: 'customer',
              businessId: 'business',
              memberId: 'customer-member',
              shopName: 'Shop',
              balanceDue: const Value(7000),
              updatedAt: DateTime.utc(2026),
            ),
          );
      final root = _paymentRow(amount: 1500, billId: 'oldest-bill');
      final rows = [
        root,
        _paymentRow(id: 'chunk', amount: 3000, billId: 'next-bill'),
        _paymentRow(id: 'credit', amount: 500),
      ];
      var rpcCalls = 0;
      final client = SupabaseClient(
        'http://localhost',
        'anon',
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/record_payment')) {
            rpcCalls++;
            return http.Response(
              jsonEncode({'payment': root, 'created': false}),
              200,
              headers: {'content-type': 'application/json'},
              request: request,
            );
          }
          expect(
            request.url.queryParameters['created_at'],
            'gt.2025-12-31T23:59:59.000Z',
          );
          return http.Response(
            jsonEncode(rows),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      );
      addTearDown(client.dispose);
      final pull = SyncPullEntities(db: db, client: client);
      await pull.upsertRemotePaymentsBatch(rows, synced: true);
      expect(
        (await (db.select(
          db.localPayments,
        )..where((p) => p.id.equals('root'))).getSingle()).amount,
        5000,
      );
      await db.setWatermark('payments', DateTime.utc(2026, 2));
      final pusher = SyncPusher(db: db, client: client);
      expect(await pusher.push(), 1);
      final watermark = (await db.watermark('payments'))!.toUtc();
      expect(watermark, DateTime.utc(2025, 12, 31, 23, 59, 59));
      await pull.pullPaymentsDelta(
        watermark.toIso8601String(),
        DateTime.utc(2026, 2),
      );
      await pull.upsertRemotePaymentsBatch(rows, synced: true);
      final local = await db.select(db.localPayments).get();
      expect(local, hasLength(3));
      expect(local.fold<int>(0, (sum, p) => sum + p.amount), 5000);
      expect(local.singleWhere((p) => p.id == 'root').billId, 'oldest-bill');
      expect((await db.select(db.localCustomers).getSingle()).balanceDue, 7000);
      expect(await pusher.push(), 0);
      expect(rpcCalls, 1);
    },
  );

  test('oldest-first account-credit receipt can have a null bill', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await _seedPayment(db, allocate: 'oldest_first');
    final client = SupabaseClient(
      'http://localhost',
      'anon',
      httpClient: MockClient(
        (request) async => http.Response(
          jsonEncode({'payment': _paymentRow(), 'created': true}),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        ),
      ),
    );
    addTearDown(client.dispose);
    expect(await SyncPusher(db: db, client: client).push(), 1);
    expect((await db.select(db.localPayments).getSingle()).billId, isNull);
  });

  test('split receipt may omit bill_id on the acknowledgement', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await _seedPayment(db, allocate: 'oldest_first');
    final row = Map<String, dynamic>.from(_paymentRow())..remove('bill_id');
    late Map<String, dynamic> requested;
    final client = SupabaseClient(
      'http://localhost',
      'anon',
      httpClient: MockClient((request) async {
        requested = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({'payment': row, 'created': true}),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
    addTearDown(client.dispose);
    expect(await SyncPusher(db: db, client: client).push(), 1);
    expect((requested['p'] as Map)['id'], 'root');
    expect((await db.select(db.localPayments).getSingle()).billId, isNull);
  });

  test('payment push resets payments bootstrap offset only', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await _seedPayment(db);
    await db.setMetaValue(syncMetaBootstrapTable, 'payments');
    await db.setMetaValue(syncMetaBootstrapOffset, '500');
    final client = SupabaseClient(
      'http://localhost',
      'anon',
      httpClient: MockClient(
        (request) async => http.Response(
          jsonEncode({'payment': _paymentRow(), 'created': true}),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        ),
      ),
    );
    addTearDown(client.dispose);
    expect(await SyncPusher(db: db, client: client).push(), 1);
    expect(await db.metaValue(syncMetaBootstrapTable), 'payments');
    expect(await db.metaValue(syncMetaBootstrapOffset), '0');
  });

  test('payment push leaves unrelated bootstrap offset', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await _seedPayment(db);
    await db.setMetaValue(syncMetaBootstrapTable, 'products');
    await db.setMetaValue(syncMetaBootstrapOffset, '200');
    final client = SupabaseClient(
      'http://localhost',
      'anon',
      httpClient: MockClient(
        (request) async => http.Response(
          jsonEncode({'payment': _paymentRow(), 'created': true}),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        ),
      ),
    );
    addTearDown(client.dispose);
    expect(await SyncPusher(db: db, client: client).push(), 1);
    expect(await db.metaValue(syncMetaBootstrapTable), 'products');
    expect(await db.metaValue(syncMetaBootstrapOffset), '200');
  });

  for (final manual in [false, true]) {
    final replies = <Object?>[
      null,
      [],
      'not an object',
      {},
      {'bill': null},
      {
        'bill': {'bill_no': 'BS-0001', 'status': 'paid'},
      },
      {
        'bill': {'id': 'other', 'bill_no': 'BS-0001', 'status': 'paid'},
      },
      {
        'bill': {'id': 'bill', 'status': 'paid'},
      },
      {
        'bill': {'id': 'bill', 'bill_no': ' ', 'status': 'paid'},
      },
      {
        'bill': {'id': 'bill', 'bill_no': 123, 'status': 'paid'},
      },
      {
        'bill': {'id': 'bill', 'bill_no': 'BS-0001'},
      },
      {
        'bill': {'id': 'bill', 'bill_no': 'BS-0001', 'status': 'invalid'},
      },
    ];
    for (var i = 0; i < replies.length; i++) {
      test(
        'malformed bill reply $i retains all pending work (manual=$manual)',
        () async {
          final db = AppDatabase.forTesting(NativeDatabase.memory());
          addTearDown(db.close);
          await db
              .into(db.localBills)
              .insert(
                LocalBillsCompanion.insert(
                  id: 'bill',
                  businessId: 'biz',
                  billNo: 'D1-1',
                  status: 'paid',
                  createdBy: 'member',
                ),
              );
          await db
              .into(db.localPayments)
              .insert(
                LocalPaymentsCompanion.insert(
                  id: 'payment',
                  businessId: 'biz',
                  customerId: 'customer',
                  billId: const Value('bill'),
                  amount: 100,
                  method: 'cash',
                  receivedBy: 'member',
                ),
              );
          await db.enqueue(
            entityType: 'bill',
            entityId: 'bill',
            payload: {
              'id': 'bill',
              'manual_sale': manual,
              'payment': {'id': 'payment', 'amount': 100},
            },
          );
          Object? reply = replies[i];
          var requests = 0;
          final client = SupabaseClient(
            'http://localhost',
            'anon',
            httpClient: MockClient((request) async {
              requests++;
              expect((jsonDecode(request.body) as Map)['p']['id'], 'bill');
              expect(
                request.url.pathSegments.last,
                manual ? 'record_customer_sale' : 'create_bill',
              );
              return http.Response(
                jsonEncode(reply),
                200,
                headers: {'content-type': 'application/json'},
                request: request,
              );
            }),
          );
          addTearDown(client.dispose);
          expect(await SyncPusher(db: db, client: client).push(), 0);
          final bill = await db.select(db.localBills).getSingle();
          expect(bill.syncStatus, 'pending');
          expect(bill.billNo, 'D1-1');
          expect(
            (await db.select(db.localPayments).getSingle()).syncStatus,
            'pending',
          );
          final queue = await db.pendingQueue();
          expect(queue.single.attempts, 1);
          expect(queue.single.lastError, isNotEmpty);
          expect(requests, 1);
          reply = {
            'bill': {'id': 'bill', 'bill_no': 'BS-0001', 'status': 'paid'},
            'created': false,
          };
          await db
              .update(db.syncQueue)
              .write(const SyncQueueCompanion(nextAttemptAt: Value(null)));
          expect(await SyncPusher(db: db, client: client).push(), 1);
          expect(requests, 2);
          expect(
            (await db.select(db.localBills).getSingle()).syncStatus,
            'synced',
          );
          expect(
            (await db.select(db.localPayments).getSingle()).syncStatus,
            'synced',
          );
          expect(await db.pendingQueue(), isEmpty);
        },
      );
    }
  }

  test(
    'pull validates bills and never acknowledges unknown entity aliases',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final client = SupabaseClient('http://localhost', 'anon');
      addTearDown(client.dispose);
      await db
          .into(db.localBills)
          .insert(
            LocalBillsCompanion.insert(
              id: 'bill',
              businessId: 'biz',
              billNo: 'D1-1',
              status: 'due',
              createdBy: 'member',
            ),
          );
      await db.enqueue(
        entityType: 'bill',
        entityId: 'bill',
        payload: {'id': 'bill'},
      );
      await db.enqueue(
        entityType: 'unknown',
        entityId: 'bill',
        payload: {'id': 'bill'},
      );
      final pull = SyncPullEntities(db: db, client: client);
      await expectLater(
        pull.upsertRemoteBillsBatch([
          {'id': 'bill', 'status': 'due'},
        ]),
        throwsFormatException,
      );
      expect(
        (await db.select(db.localBills).getSingle()).syncStatus,
        'pending',
      );
      expect(await db.pendingQueue(), hasLength(2));
      await pull.upsertRemoteBillsBatch([
        {'id': 'bill', 'status': 'due', 'bill_no': 'BS-0001'},
      ]);
      expect((await db.pendingQueue()).single.entityType, 'unknown');
    },
  );

  test(
    'late bill reply after timeout cannot acknowledge bill payment or queue',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await db
          .into(db.localBills)
          .insert(
            LocalBillsCompanion.insert(
              id: 'bill',
              businessId: 'business',
              billNo: 'D1-1',
              status: 'paid',
              createdBy: 'member',
            ),
          );
      await db
          .into(db.localPayments)
          .insert(
            LocalPaymentsCompanion.insert(
              id: 'payment',
              businessId: 'business',
              customerId: 'customer',
              billId: const Value('bill'),
              amount: 100,
              method: 'cash',
              receivedBy: 'member',
            ),
          );
      await db.enqueue(
        entityType: 'bill',
        entityId: 'bill',
        payload: {
          'id': 'bill',
          'payment': {'id': 'payment', 'amount': 100},
        },
      );
      final reply = Completer<http.Response>();
      final received = Completer<http.Request>();
      final client = SupabaseClient(
        'http://localhost',
        'anon',
        httpClient: MockClient((request) {
          received.complete(request);
          return reply.future;
        }),
      );
      addTearDown(client.dispose);
      final pending = SyncPusher(
        db: db,
        client: client,
        requestTimeout: const Duration(milliseconds: 30),
      ).push();
      final request = await received.future;
      expect(await pending, 0);
      reply.complete(
        http.Response(
          jsonEncode({
            'bill': {'id': 'bill', 'bill_no': 'BS-0001', 'status': 'paid'},
          }),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(
        (await db.select(db.localBills).getSingle()).syncStatus,
        'pending',
      );
      expect(
        (await db.select(db.localPayments).getSingle()).syncStatus,
        'pending',
      );
      expect((await db.pendingQueue()).single.attempts, 1);
    },
  );

  test('unknown entity fails instead of being acknowledged', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.enqueue(entityType: 'unknown', entityId: 'unknown', payload: {});
    final client = SupabaseClient('http://localhost', 'anon');
    addTearDown(client.dispose);
    expect(await SyncPusher(db: db, client: client).push(), 0);
    expect((await db.pendingQueue()).single.attempts, 1);
  });

  test(
    'dependency before batched prerequisite replays in the same pass',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await db.enqueue(
        entityType: 'payment',
        entityId: 'child',
        dependsOnId: 'parent',
        payload: {
          'id': 'child',
          'customer_id': 'customer',
          'amount': 5000,
          'method': 'cash',
          'received_by': 'member',
        },
      );
      await db.enqueue(
        entityType: 'stock_movement',
        entityId: 'parent',
        payload: {'id': 'parent'},
      );
      final calls = <String>[];
      final client = SupabaseClient(
        'http://localhost',
        'anon',
        httpClient: MockClient((request) async {
          calls.add(request.url.pathSegments.last);
          if (request.url.path.endsWith('/stock_movements')) {
            return http.Response('', 204, request: request);
          }
          return http.Response(
            jsonEncode({'payment': _paymentRow(id: 'child'), 'created': true}),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      );
      addTearDown(client.dispose);
      expect(await SyncPusher(db: db, client: client).push(), 2);
      expect(calls, ['stock_movements', 'record_payment']);
      expect(await db.pendingQueue(), isEmpty);
    },
  );

  test('push returns 0 for empty queue (skips second pull path)', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final pusher = SyncPusher(
      db: db,
      client: SupabaseClient('http://localhost', 'anon'),
    );
    expect(await pusher.push(), 0);
  });
}
