import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/logging/app_log.dart';
import '../../core/logging/sentry_scope.dart';
import '../../core/network/supabase_health_probe.dart';
import '../local/app_database.dart';
import 'sync_constants.dart';
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
    void Function(Duration delay, void Function() run)? scheduleRetry,
    void Function()? cancelScheduledRetry,
  }) : _db = db,
       _connectivity = connectivity ?? Connectivity(),
       _connectivityCheck = connectivityCheck,
       _reachabilityProbe = reachabilityProbe ?? isSupabaseReachable,
       _scheduleRetry = scheduleRetry,
       _cancelScheduledRetry = cancelScheduledRetry,
       _puller = SyncPuller(db: db, client: client),
       _pusher = SyncPusher(db: db, client: client);

  final AppDatabase _db;
  final Connectivity _connectivity;
  final Future<List<ConnectivityResult>> Function()? _connectivityCheck;
  final Future<bool> Function() _reachabilityProbe;
  final void Function(Duration delay, void Function() run)? _scheduleRetry;
  final void Function()? _cancelScheduledRetry;
  final SyncPuller _puller;
  final SyncPusher _pusher;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  final SyncCoalesce _coalesce = SyncCoalesce();
  final ReachabilityBackoff _reachabilityBackoff = ReachabilityBackoff();
  Timer? _reachabilityTimer;
  bool _retryArmed = false;

  /// True when the last bootstrap pass hit page/duration budget.
  bool get bootstrapIncomplete => _puller.bootstrapIncomplete;

  Future<void> init(String deviceId) async {
    await _db.ensureDeviceMeta(deviceId);
    _connectivitySub ??= _connectivity.onConnectivityChanged.listen((_) {
      unawaited(syncNow());
    });
    AppLog.info(
      'sync_init',
      extras: {'deviceIdPrefix': deviceId.substring(0, 8)},
    );
    try {
      await syncNow(initial: true);
    } catch (e, st) {
      AppLog.warn('Initial sync failed (will retry later)', e, st, {
        'phase': 'initial_sync',
      });
      _armReachabilityRetry();
    }
  }

  Future<int> failedCount() => _db.failedCount();

  Future<void> retryFailed() async {
    await _db.retryFailed();
    await syncNow();
  }

  void dispose() {
    unawaited(_connectivitySub?.cancel());
    _connectivitySub = null;
    _clearReachabilityRetry();
  }

  Future<bool> get isOnline async {
    final results =
        await (_connectivityCheck?.call() ?? _connectivity.checkConnectivity());
    if (!results.any((r) => r != ConnectivityResult.none)) return false;
    return _reachabilityProbe();
  }

  void _armReachabilityRetry() {
    if (_retryArmed) return;
    _retryArmed = true;
    final delay = _reachabilityBackoff.next();
    void run() {
      _retryArmed = false;
      unawaited(syncNow());
    }

    final scheduleRetry = _scheduleRetry;
    if (scheduleRetry != null) {
      scheduleRetry(delay, run);
      return;
    }
    _reachabilityTimer?.cancel();
    _reachabilityTimer = Timer(delay, run);
  }

  void _clearReachabilityRetry() {
    _reachabilityTimer?.cancel();
    _reachabilityTimer = null;
    _retryArmed = false;
    _reachabilityBackoff.reset();
    _cancelScheduledRetry?.call();
  }

  Future<void> syncNow({bool initial = false}) async {
    if (_coalesce.syncing) {
      _coalesce.markQueuedIfBusy();
      return;
    }
    if (!await isOnline) {
      _armReachabilityRetry();
      return;
    }
    if (!_coalesce.tryEnter()) return;

    final started = DateTime.now().toUtc();
    final pendingStart = await _db.pendingCount();
    addSyncStartBreadcrumb(pendingCount: pendingStart);

    try {
      do {
        _coalesce.clearQueued();
        await _puller.pull();
        if (initial) {
          AppLog.info(
            'initial_sync_pull_complete',
            extras: {'bootstrapIncomplete': _puller.bootstrapIncomplete},
          );
        }
        final uploaded = await _pusher.push();
        if (uploaded > 0) {
          await _puller.pull();
        }
      } while (_coalesce.shouldRepeat);
      await _db.pruneSyncedQueue();
      await _db.setMetaValue(
        syncMetaLastSuccessAt,
        DateTime.now().toUtc().toIso8601String(),
      );
      _clearReachabilityRetry();
    } catch (e, st) {
      AppLog.warn('sync failed; will retry', e, st, {'phase': 'sync_now'});
      _armReachabilityRetry();
      rethrow;
    } finally {
      final duration = DateTime.now().toUtc().difference(started);
      final pendingEnd = await _db.pendingCount();
      addSyncEndBreadcrumb(
        duration: duration,
        pendingCount: pendingEnd,
        bootstrapIncomplete: _puller.bootstrapIncomplete,
      );
      AppLog.info(
        'sync_complete',
        extras: {
          'durationMs': duration.inMilliseconds,
          'pendingCount': pendingEnd,
          'bootstrapIncomplete': _puller.bootstrapIncomplete,
          'initial': initial,
        },
      );
      _coalesce.end();
    }
  }

  String newId() => _uuid.v4();
}
