import 'package:businesssajilo/data/local/app_database.dart';
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

  test('syncNow schedules a reachability retry when Supabase is down', () async {
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
    expect(scheduled, [const Duration(seconds: 5)],
        reason: 'already-armed retry must not stack');

    sync.dispose();
    expect(pending, isNull);
  });
}
