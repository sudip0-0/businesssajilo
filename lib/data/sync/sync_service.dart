import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/env.dart';
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
    Future<List<ConnectivityResult>> Function()? connectivityCheck,
    Future<bool> Function()? reachabilityProbe,
  }) : _db = db,
       _connectivity = connectivity ?? Connectivity(),
       _connectivityCheck = connectivityCheck,
       _reachabilityProbe = reachabilityProbe ?? _defaultReachabilityProbe,
       _puller = SyncPuller(db: db, client: client),
       _pusher = SyncPusher(db: db, client: client);

  final AppDatabase _db;
  final Connectivity _connectivity;
  final Future<List<ConnectivityResult>> Function()? _connectivityCheck;
  final Future<bool> Function() _reachabilityProbe;
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

  /// True when the device has a non-none link *and* the Supabase host is
  /// reachable (avoids captive-portal false positives).
  Future<bool> get isOnline async {
    final results =
        await (_connectivityCheck?.call() ?? _connectivity.checkConnectivity());
    if (!results.any((r) => r != ConnectivityResult.none)) return false;
    return _reachabilityProbe();
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
      await _db.pruneSyncedQueue();
    } finally {
      _coalesce.end();
    }
  }

  String newId() => _uuid.v4();

  /// Lightweight HEAD/GET against Supabase Auth health endpoint.
  static Future<bool> _defaultReachabilityProbe() async {
    final base = Env.supabaseUrl;
    if (base.isEmpty) return false;
    final uri = Uri.parse('$base/auth/v1/health');
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
    try {
      final request = await client
          .getUrl(uri)
          .timeout(const Duration(seconds: 3));
      final response = await request.close().timeout(
        const Duration(seconds: 3),
      );
      await response.drain<void>();
      return response.statusCode < 500;
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }
}
