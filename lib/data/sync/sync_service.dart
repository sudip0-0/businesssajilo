import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../local/app_database.dart';
import 'sync_helpers.dart';
import 'sync_puller.dart';
import 'sync_pusher.dart';

const _uuid = Uuid();

class SyncService {
  SyncService({
    required AppDatabase db,
    required SupabaseClient client,
    Connectivity? connectivity,
  }) : _db = db,
       _connectivity = connectivity ?? Connectivity(),
       _puller = SyncPuller(db: db, client: client),
       _pusher = SyncPusher(db: db, client: client);

  final AppDatabase _db;
  final Connectivity _connectivity;
  final SyncPuller _puller;
  final SyncPusher _pusher;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  final SyncCoalesce _coalesce = SyncCoalesce();

  Future<void> init(String deviceId) async {
    await _db.ensureDeviceMeta(deviceId);
    _connectivitySub ??= _connectivity.onConnectivityChanged.listen((_) {
      unawaited(syncNow());
    });
    // Initial sync is best-effort: a network failure must not break init.
    try {
      await syncNow();
    } catch (e) {
      debugPrint('Initial sync failed (will retry later): $e');
    }
  }

  /// Number of terminally failed queue items.
  Future<int> failedCount() => _db.failedCount();

  /// Resets failed items and triggers a sync.
  Future<void> retryFailed() async {
    await _db.retryFailed();
    await syncNow();
  }

  void dispose() {
    unawaited(_connectivitySub?.cancel());
    _connectivitySub = null;
  }

  Future<bool> get isOnline async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  Future<void> syncNow() async {
    if (_coalesce.syncing) {
      _coalesce.markQueuedIfBusy();
      return;
    }
    if (!await isOnline) return;
    // Re-check after the async online probe — another sync may have started.
    if (!_coalesce.tryEnter()) return;
    try {
      do {
        _coalesce.clearQueued();
        await _puller.pull();
        await _pusher.push();
        await _puller.pull();
      } while (_coalesce.shouldRepeat);
    } finally {
      _coalesce.end();
    }
  }

  String newId() => _uuid.v4();
}
