import 'package:businesssajilo/data/local/app_database.dart';
import 'package:businesssajilo/data/sync/sync_bundle_registry.dart';
import 'package:businesssajilo/data/sync/sync_providers.dart';
import 'package:businesssajilo/data/sync/sync_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _FakeSync extends Mock implements SyncService {}

void main() {
  tearDown(() async {
    await SyncBundleRegistry.instance.disposeActive();
  });

  test('replace then dispose clears active bundle', () async {
    final registry = SyncBundleRegistry.instance;
    expect(registry.active, isNull);

    final sync = _FakeSync();
    when(sync.dispose).thenReturn(null);

    final db = AppDatabase.forTesting(NativeDatabase.memory());
    registry.replace(
      SyncBundle(
        db: db,
        sync: sync,
        businessId: 'biz',
        memberId: 'mem',
      ),
    );
    expect(registry.active, isNotNull);

    await registry.disposeActive();
    expect(registry.active, isNull);
    verify(sync.dispose).called(1);
  });

  test('replace overwrites previous pointer without disposing it', () async {
    final registry = SyncBundleRegistry.instance;
    final syncA = _FakeSync();
    final syncB = _FakeSync();
    when(syncA.dispose).thenReturn(null);
    when(syncB.dispose).thenReturn(null);

    final dbA = AppDatabase.forTesting(NativeDatabase.memory());
    final dbB = AppDatabase.forTesting(NativeDatabase.memory());
    registry.replace(
      SyncBundle(db: dbA, sync: syncA, businessId: 'a', memberId: 'm'),
    );
    final orphan = registry.active;
    registry.replace(
      SyncBundle(db: dbB, sync: syncB, businessId: 'b', memberId: 'm'),
    );
    expect(registry.active?.businessId, 'b');
    verifyNever(syncA.dispose);
    // Clean up the orphaned first bundle for the test harness.
    orphan?.sync.dispose();
    await orphan?.db.close();
  });
}
