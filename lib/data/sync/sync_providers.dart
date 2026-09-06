import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../domain/enums.dart';
import '../../domain/models/session_state.dart';
import '../local/app_database.dart';
import '../local/legacy_cache_recovery.dart';
import 'sync_bundle_registry.dart';
import 'sync_config.dart';
import 'sync_constants.dart';
import 'sync_models.dart';
import 'sync_service.dart';

class SyncBundle {
  SyncBundle({
    required this.db,
    required this.sync,
    required this.businessId,
    required this.memberId,
    this.recoverPreviousWork,
  });

  final AppDatabase db;
  final SyncService sync;
  final String businessId;
  final String memberId;
  final Future<void> Function()? recoverPreviousWork;
}

final legacyRecoveryNoticeProvider = FutureProvider<String?>((ref) async {
  final bundle = ref.watch(syncBundleProvider);
  return bundle?.db.metaValue(legacyRecoveryNoticeKey);
});

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
    this.lastSuccessAt,
  });

  final SyncState state;
  final int pendingCount;
  final int failedCount;
  final bool bootstrapIncomplete;
  final DateTime? lastSuccessAt;

  /// Changes when queued work or a successful pull/push may have rewritten
  /// local lists. IndexedStack pagers and report providers watch this.
  (int, int, SyncState, DateTime?) get refreshEpoch =>
      (pendingCount, failedCount, state, lastSuccessAt);
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
    final lastRaw = await bundle.db.metaValue(syncMetaLastSuccessAt);
    final lastSuccessAt = lastRaw == null || lastRaw.isEmpty
        ? null
        : DateTime.tryParse(lastRaw);
    if (controller.isClosed) return;
    controller.add(
      SyncStatus(
        state: state,
        pendingCount: pending,
        failedCount: failed,
        bootstrapIncomplete: incomplete,
        lastSuccessAt: lastSuccessAt,
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

int _syncGeneration = 0;

Future<void> bootstrapSyncForSession({
  required SupabaseClient client,
  required String businessId,
  required String memberId,
  required Role role,
  bool includeCustomerBalances = true,
}) async {
  final generation = ++_syncGeneration;
  final authUserId = client.auth.currentUser?.id;
  await SyncBundleRegistry.instance.disposeActive();
  if (generation != _syncGeneration) return;

  final db = AppDatabase.open(
    businessId: businessId,
    memberId: memberId,
    role: role,
  );
  // Tenant isolation: wipe all cached rows, watermarks, and queued mutations
  // when the active business changes so data never leaks across tenants.
  final deviceId = const Uuid().v4();
  try {
    await db.prepareForBusiness(businessId);
    await db.ensureDeviceMeta(deviceId);
    await recoverPreviousCaches(
      db: db,
      businessId: businessId,
      memberId: memberId,
      role: role,
    );
  } catch (_) {
    await db.close();
    rethrow;
  }

  final sync = SyncService(
    db: db,
    client: client,
    includeCustomerBalances:
        role.canViewCustomerBalance && includeCustomerBalances,
    isSessionCurrent: () =>
        generation == _syncGeneration &&
        client.auth.currentUser?.id == authUserId,
  );
  try {
    await sync.init(deviceId);
    if (generation != _syncGeneration ||
        client.auth.currentUser?.id != authUserId) {
      await sync.close();
      await db.close();
      return;
    }
    SyncBundleRegistry.instance.replace(
      SyncBundle(
        db: db,
        sync: sync,
        businessId: businessId,
        memberId: memberId,
        recoverPreviousWork: () async {
          if (!sync.isActive) return;
          await recoverPreviousCaches(
            db: db,
            businessId: businessId,
            memberId: memberId,
            role: role,
          );
          await sync.syncNow();
        },
      ),
    );
  } catch (_) {
    await sync.close();
    await db.close();
    rethrow;
  }
}

Future<void> disposeSyncBundle() async {
  _syncGeneration++;
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
  if (client.auth.currentUser?.id != session.user?.id ||
      client.auth.currentUser?.id != session.member!.authUserId) {
    await disposeSyncBundle();
    return;
  }
  await bootstrapSyncForSession(
    client: client,
    businessId: session.member!.businessId,
    memberId: session.member!.id,
    role: session.member!.role,
    includeCustomerBalances: session.member!.role.canViewCustomerBalance,
  );
}
