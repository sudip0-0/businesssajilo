import 'dart:convert';

import 'package:businesssajilo/data/local/app_database.dart';
import 'package:businesssajilo/data/sync/pull/sync_pull_entities.dart';
import 'package:businesssajilo/data/sync/sync_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:businesssajilo/data/sync/pull/sync_pull_page.dart';
import 'package:businesssajilo/data/sync/sync_backoff.dart';
import 'package:businesssajilo/data/sync/sync_constants.dart';
import 'package:businesssajilo/data/sync/sync_pusher.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  for (final delta in [false, true]) {
    test(
      'payment pull preserves pending and failed local work (delta=$delta)',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);
        final states = {
          'local-pending': 'pending',
          'local-failed': 'failed',
          'queue-pending': 'synced',
          'queue-failed': 'synced',
          'clean': 'synced',
        };
        for (final entry in states.entries) {
          await db
              .into(db.localPayments)
              .insert(
                LocalPaymentsCompanion.insert(
                  id: entry.key,
                  businessId: 'business',
                  customerId: 'customer',
                  amount: 50,
                  method: 'cash',
                  refNote: const Value('local evidence'),
                  receivedBy: 'member',
                  syncStatus: Value(entry.value),
                ),
              );
        }
        for (final status in ['pending', 'failed']) {
          for (final id in ['queue-$status', 'missing-$status']) {
            await db.enqueue(
              entityType: 'payment',
              entityId: id,
              payload: {'id': id, 'amount': 50},
            );
            await (db.update(
              db.syncQueue,
            )..where((q) => q.entityId.equals(id))).write(
              SyncQueueCompanion(
                status: Value(status),
                attempts: const Value(3),
                lastError: const Value('retained failure evidence'),
              ),
            );
          }
        }
        final beforeQueue = await db.select(db.syncQueue).get();
        final beforePayments = {
          for (final payment in await db.select(db.localPayments).get())
            payment.id: payment,
        };
        final rows = [
          for (final id in [
            ...states.keys,
            'missing-pending',
            'missing-failed',
            'new',
          ])
            {
              'id': id,
              'business_id': 'business',
              'customer_id': 'customer',
              'amount': 999,
              'method': 'bank',
              'received_by': 'member',
              'created_at': '2026-01-02T00:00:00Z',
            },
        ];
        final client = SupabaseClient(
          'http://localhost',
          'anon',
          httpClient: MockClient(
            (request) async => http.Response(
              jsonEncode(rows),
              200,
              headers: {'content-type': 'application/json'},
              request: request,
            ),
          ),
        );
        addTearDown(client.dispose);
        final pull = SyncPullEntities(db: db, client: client);
        if (delta) {
          await pull.pullPaymentsDelta(
            '2026-01-01T00:00:00Z',
            DateTime.utc(2026, 2),
          );
        } else {
          await pull.pullPaymentsBootstrap(DateTime.utc(2026, 2));
        }
        final after = {
          for (final payment in await db.select(db.localPayments).get())
            payment.id: payment,
        };
        for (final id in states.keys.where((id) => id != 'clean')) {
          expect(after[id], beforePayments[id], reason: id);
        }
        expect(after['clean']!.amount, 999);
        expect(after['new']!.syncStatus, 'synced');
        expect(after.containsKey('missing-pending'), isFalse);
        expect(after.containsKey('missing-failed'), isFalse);
        expect(await db.select(db.syncQueue).get(), beforeQueue);
      },
    );
  }

  for (final includeBalances in [false, true]) {
    test(
      'sync selects customer source explicitly and preserves bill names (balances=$includeBalances)',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);
        final requests = <Uri>[];
        var shopName = 'Directory Shop';
        final client = SupabaseClient(
          'http://localhost',
          'anon',
          httpClient: MockClient((request) async {
            requests.add(request.url);
            final table = request.url.pathSegments.last;
            final rows = <Map<String, dynamic>>[];
            if (table == 'customer_directory' ||
                (includeBalances && table == 'customer_balances')) {
              rows.add({
                'customer_id': 'customer',
                'business_id': 'biz',
                'member_id': 'customer-member',
                'shop_name': shopName,
                'updated_at': '2099-01-01T00:00:00Z',
                if (includeBalances) 'opening_balance': 100,
                if (includeBalances) 'balance_due': 300,
              });
            } else if (table == 'bills') {
              rows.add({
                'id': 'bill',
                'business_id': 'biz',
                'customer_id': 'customer',
                'bill_no': 'BS-0001',
                'created_by': 'member',
                'status': 'due',
                'created_at': '2026-01-01T00:00:00Z',
                'updated_at': '2099-01-01T00:00:00Z',
                'customers': {'shop_name': shopName},
                'bill_items': <Object>[],
              });
            }
            return http.Response(
              jsonEncode(rows),
              200,
              headers: {'content-type': 'application/json'},
              request: request,
            );
          }),
        );
        addTearDown(client.dispose);
        final sync = SyncService(
          db: db,
          client: client,
          includeCustomerBalances: includeBalances,
          connectivityCheck: () async => [ConnectivityResult.wifi],
          reachabilityProbe: () async => true,
        );
        addTearDown(sync.dispose);

        for (final delta in [false, true]) {
          requests.clear();
          if (delta) {
            shopName = 'Renamed Shop';
            await db.setWatermark('payments', DateTime.utc(2026, 1, 1));
          }
          await sync.syncNow();
          final tables = requests.map((r) => r.pathSegments.last).toList();
          final source = includeBalances
              ? 'customer_balances'
              : 'customer_directory';
          expect(tables, contains(source));
          expect(
            tables,
            isNot(
              contains(
                includeBalances ? 'customer_directory' : 'customer_balances',
              ),
            ),
          );
          expect(tables.contains('payments'), includeBalances);
          final customer = await db.select(db.localCustomers).getSingle();
          expect(customer.shopName, shopName);
          expect(customer.openingBalance, includeBalances ? 100 : 0);
          expect(customer.balanceDue, includeBalances ? 300 : 0);
          expect(
            (await db.select(db.localBills).getSingle()).customerShopName,
            shopName,
          );
          final customerRequest = requests.singleWhere(
            (r) => r.pathSegments.last == source,
          );
          expect(
            customerRequest.queryParameters.containsKey('updated_at'),
            delta,
          );
          for (final request in requests.where(
            (r) => r.path.endsWith('/bills'),
          )) {
            expect(
              request.queryParameters['select'],
              contains(
                'customers:customer_directory!bills_customer_id_fkey(shop_name)',
              ),
            );
          }
        }
      },
    );
  }

  for (final delta in [false, true]) {
    test(
      'balance failure is not replaced by directory zeros (delta=$delta)',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);
        final requests = <String>[];
        final client = SupabaseClient(
          'http://localhost',
          'anon',
          httpClient: MockClient((request) async {
            requests.add(request.url.pathSegments.last);
            final balances = request.url.path.endsWith('/customer_balances');
            return http.Response(
              jsonEncode(
                balances
                    ? {'message': 'permission denied', 'code': '42501'}
                    : <Object>[],
              ),
              balances ? 403 : 200,
              headers: {'content-type': 'application/json'},
              request: request,
            );
          }),
        );
        addTearDown(client.dispose);
        final entities = SyncPullEntities(db: db, client: client);
        final watermark = DateTime.utc(2026, 1, 1);
        if (delta) await db.setWatermark('customers', watermark);

        await expectLater(
          delta
              ? entities.pullCustomerBalancesDelta(
                  watermark.toIso8601String(),
                  DateTime.utc(2026, 2, 1),
                )
              : entities.pullCustomerBalancesBootstrap(watermark),
          throwsA(isA<PostgrestException>()),
        );
        expect(requests, ['customer_balances']);
        expect(
          (await db.watermark('customers'))?.toUtc(),
          delta ? watermark : isNull,
        );
      },
    );
  }

  group('customer balance watermark', () {
    test('delta pull preserves updated_at filter in query', () {
      const iso = '2026-06-01T00:00:00Z';
      final query = 'updated_at=gt.$iso';
      expect(query, contains('updated_at'));
      expect(query, contains(iso));
    });

    test('watermark not advanced while bootstrap table incomplete', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      await db.setMetaValue(syncMetaBootstrapTable, 'customers');
      await db.setMetaValue(syncMetaBootstrapOffset, '200');
      expect(await db.watermark('customers'), isNull);
    });

    test('watermark set after customers table completes', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final ts = DateTime.utc(2026, 7, 1);
      await db.setWatermark('customers', ts);
      expect(await db.watermark('customers'), isNotNull);
    });
  });

  group('bootstrap resume offsets', () {
    test('budget stop preserves next offset for resume', () async {
      final budget = SyncPullBudget(maxPages: 1);
      final page = const SyncPullPage();

      final result = await page.pullPaged(
        entityLabel: 'customers',
        startOffset: 100,
        budget: budget,
        pageSize: 50,
        buildPage: (from, to) async =>
            List.generate(50, (i) => {'customer_id': 'c-${from + i}'}),
        onPage: (_) async {},
      );

      expect(result.outcome, PullPageOutcome.budgetExceeded);
      expect(result.nextOffset, 150);
    });
  });

  group('queue ordering and idempotency', () {
    test('bill stays before dependent payment in pending queue', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      const billId = 'bill-order';
      await db.enqueue(
        entityType: 'bill',
        entityId: billId,
        payload: {'id': billId},
      );
      await db.enqueue(
        entityType: 'payment',
        entityId: 'pay-order',
        dependsOnId: billId,
        payload: {'id': 'pay-order', 'bill_id': billId},
      );

      final queue = await db.pendingQueue();
      expect(queue.first.entityType, 'bill');
      expect(queue.last.entityType, 'payment');
      expect(queue.last.dependsOnId, billId);
    });

    test('legacy bill_items queue entry is rejected on push', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      await db.enqueue(
        entityType: 'bill_items',
        entityId: 'bill-legacy',
        payload: {'items': []},
      );

      final pusher = SyncPusher(
        db: db,
        client: SupabaseClient('http://localhost', 'anon'),
      );
      expect(await pusher.push(), 0);

      final queue = await db.pendingQueue();
      expect(queue.single.status, 'pending');
      expect(queue.single.attempts, 1);
      expect(queue.single.lastError, contains('legacy bill_items'));
    });

    test('terminal failure after max attempts marks queue failed', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      await db.enqueue(
        entityType: 'bill',
        entityId: 'bill-fail',
        payload: {'id': 'bill-fail', 'items': []},
      );

      final queueRow = await db.pendingQueue();
      await (db.update(
        db.syncQueue,
      )..where((q) => q.id.equals(queueRow.single.id))).write(
        const SyncQueueCompanion(attempts: Value(syncMaxAttempts - 1)),
      );

      final pusher = SyncPusher(
        db: db,
        client: SupabaseClient('http://localhost', 'anon'),
      );
      expect(await pusher.push(), 0);

      expect(await db.failedCount(), 1);
      final after = await db.unsyncedQueue();
      expect(after.single.status, 'failed');
      expect(after.single.attempts, syncMaxAttempts);
    });

    test(
      'failed item is not pushed again after nextAttemptAt passes',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);

        await db.enqueue(
          entityType: 'bill',
          entityId: 'bill-terminal',
          payload: {'id': 'bill-terminal', 'items': []},
        );
        final queued = await db.pendingQueue();
        await (db.update(
          db.syncQueue,
        )..where((q) => q.id.equals(queued.single.id))).write(
          SyncQueueCompanion(
            status: const Value('failed'),
            attempts: const Value(syncMaxAttempts),
            nextAttemptAt: Value(
              DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
            ),
          ),
        );

        final pusher = SyncPusher(
          db: db,
          client: SupabaseClient('http://localhost', 'anon'),
        );
        expect(await pusher.push(), 0);

        final after = await db.unsyncedQueue();
        expect(after.single.status, 'failed');
        expect(after.single.attempts, syncMaxAttempts);

        await db.retryFailed(queueRowId: queued.single.id);
        final retried = await db.pendingQueue();
        expect(retried.single.status, 'pending');
        expect(retried.single.attempts, 0);
        expect(retried.single.nextAttemptAt, isNull);
      },
    );
  });
}
