import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/session_state.dart';
import '../local/app_database.dart';
import 'sync_bundle_registry.dart';
import 'sync_config.dart';
import 'sync_models.dart';
import 'sync_service.dart';

class SyncBundle {
  SyncBundle({
    required this.db,
    required this.sync,
    required this.businessId,
    required this.memberId,
  });

  final AppDatabase db;
  final SyncService sync;
  final String businessId;
  final String memberId;
}

/// Bumped whenever the active bundle changes, so [syncBundleProvider] can be
/// refreshed from the auth notifier without `ref.invalidate` (which riverpod
/// flags as a circular dependency).
final syncBundleVersionProvider = NotifierProvider<SyncBundleVersion, int>(
  SyncBundleVersion.new,
);

class SyncBundleVersion extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final syncBundleProvider = Provider<SyncBundle?>((ref) {
  // Only watch the version bump — auth calls bump() after bootstrap/dispose
  // so we avoid a data→features circular dependency on authProvider.
  ref.watch(syncBundleVersionProvider);
  return SyncBundleRegistry.instance.active;
});

final syncServiceProvider = Provider<SyncService?>((ref) {
  return ref.watch(syncBundleProvider)?.sync;
});

class SyncStatus {
  const SyncStatus({
    required this.state,
    this.pendingCount = 0,
    this.failedCount = 0,
    this.bootstrapIncomplete = false,
  });

  final SyncState state;
  final int pendingCount;
  final int failedCount;
  final bool bootstrapIncomplete;
}

/// Reactive sync status: re-evaluates on queue changes (drift `.watch()`)
/// and on connectivity changes — no polling loop.
final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final bundle = ref.watch(syncBundleProvider);
  if (bundle == null) {
    return Stream.value(const SyncStatus(state: SyncState.synced));
  }

  final controller = StreamController<SyncStatus>();

  Future<void> emit() async {
    if (controller.isClosed) return;
    final online = await bundle.sync.isOnline;
    final pending = await bundle.db.pendingCount();
    final failed = await bundle.db.failedCount();
    final incomplete = bundle.sync.bootstrapIncomplete;
    final state = !online
        ? SyncState.offline
        : incomplete
        ? SyncState.incomplete
        : pending > 0
        ? SyncState.pending
        : SyncState.synced;
    if (controller.isClosed) return;
    controller.add(
      SyncStatus(
        state: state,
        pendingCount: pending,
        failedCount: failed,
        bootstrapIncomplete: incomplete,
      ),
    );
  }

  final queueSub = bundle.db.watchUnsyncedQueue().listen(
    (_) => unawaited(emit()),
  );
  final connectivitySub = Connectivity().onConnectivityChanged.listen(
    (_) => unawaited(emit()),
  );
  unawaited(emit());

  ref.onDispose(() {
    unawaited(queueSub.cancel());
    unawaited(connectivitySub.cancel());
    unawaited(controller.close());
  });
  return controller.stream;
});

/// Live view of the local sync queue (pending + failed items).
final syncQueueProvider = StreamProvider<List<SyncQueueData>>((ref) {
  final bundle = ref.watch(syncBundleProvider);
  if (bundle == null) return Stream.value(const <SyncQueueData>[]);
  return bundle.db.watchUnsyncedQueue();
});

Future<void> bootstrapSyncForSession({
  required SupabaseClient client,
  required String businessId,
  required String memberId,
}) async {
  await disposeSyncBundle();

  final db = AppDatabase.open();
  // Tenant isolation: wipe all cached rows, watermarks, and queued mutations
  // when the active business changes so data never leaks across tenants.
  await db.prepareForBusiness(businessId);

  final deviceId = const Uuid().v4();
  await db.ensureDeviceMeta(deviceId);

  final sync = SyncService(db: db, client: client);
  await sync.init(deviceId);

  SyncBundleRegistry.instance.replace(
    SyncBundle(
      db: db,
      sync: sync,
      businessId: businessId,
      memberId: memberId,
    ),
  );
}

Future<void> disposeSyncBundle() async {
  await SyncBundleRegistry.instance.disposeActive();
}

Future<void> syncBootstrapForSession(SessionState session) async {
  if (!session.isAuthenticated || session.member == null) {
    await disposeSyncBundle();
    return;
  }
  if (!syncEnabledFor(session.member!.role)) {
    await disposeSyncBundle();
    return;
  }
  final client = Supabase.instance.client;
  await bootstrapSyncForSession(
    client: client,
    businessId: session.member!.businessId,
    memberId: session.member!.id,
  );
}
