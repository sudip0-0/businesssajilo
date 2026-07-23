import 'package:businesssajilo/data/sync/sync_pusher.dart';
import 'package:businesssajilo/data/local/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
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
