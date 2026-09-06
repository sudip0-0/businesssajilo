import 'dart:async';
import 'dart:convert';

import 'package:businesssajilo/data/local/app_database.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:businesssajilo/data/sync/sync_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'session change discards in-flight pull and leaves queued work intact',
    () async {
      final received = Completer<void>();
      final reply = Completer<void>();
      var current = true;
      var calls = 0;
      final client = SupabaseClient(
        'http://localhost',
        'anon',
        httpClient: MockClient((request) async {
          calls++;
          received.complete();
          await reply.future;
          return http.Response(
            jsonEncode([
              {
                'id': 'private-product',
                'business_id': 'old-business',
                'name': 'Private',
                'unit': 'piece',
                'updated_at': '2026-01-01T00:00:00Z',
              },
            ]),
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
        isSessionCurrent: () => current,
        connectivityCheck: () async => [ConnectivityResult.wifi],
        reachabilityProbe: () async => true,
        scheduleRetry: (_, _) =>
            fail('inactive session must not schedule retries'),
      );
      await db.enqueue(
        entityType: 'payment',
        entityId: 'payment',
        payload: {'id': 'payment'},
      );
      final running = sync.syncNow();
      await received.future;
      current = false;
      var closed = false;
      final closing = sync.close().then((_) => closed = true);
      await Future<void>.delayed(Duration.zero);
      expect(closed, isFalse);
      reply.complete();
      await running;
      await closing;
      expect(calls, 1);
      expect(await db.select(db.localProducts).get(), isEmpty);
      expect((await db.pendingQueue()).single.attempts, 0);
      await sync.syncNow();
      expect(calls, 1);
    },
  );

  test('shutdown bounds a hung pull and ignores its late response', () async {
    final received = Completer<http.Request>();
    final response = Completer<http.Response>();
    final client = SupabaseClient(
      'http://localhost',
      'anon',
      httpClient: MockClient((request) {
        received.complete(request);
        return response.future;
      }),
    );
    addTearDown(client.dispose);
    final sync = SyncService(
      db: db,
      client: client,
      requestTimeout: const Duration(milliseconds: 30),
      connectivityCheck: () async => [ConnectivityResult.wifi],
      reachabilityProbe: () async => true,
    );
    final running = sync.syncNow();
    final request = await received.future;
    await sync.close().timeout(const Duration(seconds: 1));
    await running;
    await db.close();
    response.complete(
      http.Response(
        '[]',
        200,
        headers: {'content-type': 'application/json'},
        request: request,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(sync.isActive, isFalse);
  });

  test(
    'syncNow schedules a reachability retry when Supabase is down',
    () async {
      final scheduled = <Duration>[];
      void Function()? pending;
      final sync = SyncService(
        db: db,
        client: SupabaseClient('http://localhost', 'anon'),
        connectivityCheck: () async => const [ConnectivityResult.wifi],
        reachabilityProbe: () async => false,
        scheduleRetry: (delay, run) {
          scheduled.add(delay);
          pending = run;
        },
        cancelScheduledRetry: () => pending = null,
      );

      await sync.syncNow();
      expect(scheduled, [const Duration(seconds: 5)]);

      await sync.syncNow();
      expect(scheduled, [
        const Duration(seconds: 5),
      ], reason: 'already-armed retry must not stack');

      sync.dispose();
      expect(pending, isNull);
    },
  );
}
