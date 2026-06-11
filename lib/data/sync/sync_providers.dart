import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/ui/sync_badge.dart';
import '../../domain/models/session_state.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../local/app_database.dart';
import 'sync_config.dart';
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

SyncBundle? _activeBundle;

final syncBundleProvider = Provider<SyncBundle?>((ref) {
  ref.watch(authProvider);
  return _activeBundle;
});

final syncServiceProvider = Provider<SyncService?>((ref) {
  return ref.watch(syncBundleProvider)?.sync;
});

class SyncStatus {
  const SyncStatus({
    required this.state,
    this.pendingCount = 0,
  });

  final SyncState state;
  final int pendingCount;
}

final syncStatusProvider = StreamProvider<SyncStatus>((ref) async* {
  final bundle = ref.watch(syncBundleProvider);
  if (bundle == null) {
    yield const SyncStatus(state: SyncState.synced);
    return;
  }

  while (true) {
    final online = await bundle.sync.isOnline;
    final pending = await bundle.db.pendingCount();
    final state = !online
        ? SyncState.offline
        : pending > 0
            ? SyncState.pending
            : SyncState.synced;
    yield SyncStatus(state: state, pendingCount: pending);
    await Future<void>.delayed(const Duration(seconds: 2));
  }
});

Future<void> bootstrapSyncForSession({
  required SupabaseClient client,
  required String businessId,
  required String memberId,
}) async {
  await disposeSyncBundle();

  final db = AppDatabase.open();
  final deviceId = const Uuid().v4();
  await db.ensureDeviceMeta(deviceId);

  final sync = SyncService(db: db, client: client);
  await sync.init(deviceId);

  _activeBundle = SyncBundle(
    db: db,
    sync: sync,
    businessId: businessId,
    memberId: memberId,
  );
}

Future<void> disposeSyncBundle() async {
  _activeBundle?.sync.dispose();
  await _activeBundle?.db.close();
  _activeBundle = null;
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
