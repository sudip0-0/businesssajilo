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
    bool includeCustomerBalances = true,
    bool Function()? isSessionCurrent,
    Duration requestTimeout = const Duration(seconds: 15),
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
       _requestTimeout = requestTimeout,
       _isSessionCurrent = isSessionCurrent {
    _puller = SyncPuller(
      db: db,
      client: client,
      includeCustomerBalances: includeCustomerBalances,
      isActive: () => isActive,
      requestTimeout: requestTimeout,
    );
    _pusher = SyncPusher(
      db: db,
      client: client,
      isActive: () => isActive,
      requestTimeout: requestTimeout,
    );
  }

  final AppDatabase _db;
  final Connectivity _connectivity;
  final Future<List<ConnectivityResult>> Function()? _connectivityCheck;
  final Future<bool> Function() _reachabilityProbe;
  final void Function(Duration delay, void Function() run)? _scheduleRetry;
  final void Function()? _cancelScheduledRetry;
  final bool Function()? _isSessionCurrent;
  final Duration _requestTimeout;
  late final SyncPuller _puller;
  late final SyncPusher _pusher;
  bool _disposed = false;
  Future<void>? _running;

  bool get isActive => !_disposed && (_isSessionCurrent?.call() ?? true);

  Future<void> close() async {
    dispose();
    try {
      await _running;
    } catch (_) {}
  }

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

  Future<void> retryFailed({int? queueRowId}) async {
    await _db.retryFailed(queueRowId: queueRowId);
    await syncNow();
  }

  void dispose() {
    _disposed = true;
    unawaited(_connectivitySub?.cancel());
    _connectivitySub = null;
    _clearReachabilityRetry();
  }

  Future<bool> get isOnline async {
    if (!isActive) return false;
    return (() async {
      final results =
          await (_connectivityCheck?.call() ??
              _connectivity.checkConnectivity());
      if (!isActive || !results.any((r) => r != ConnectivityResult.none)) {
        return false;
      }
      return _reachabilityProbe();
    })().timeout(_requestTimeout, onTimeout: () => false);
  }

  void _armReachabilityRetry() {
    if (!isActive || _retryArmed) return;
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

  Future<void> syncNow({bool initial = false}) {
    if (!isActive) return Future.value();
    final running = _running;
    if (running != null) {
      _coalesce.markQueuedIfBusy();
      return running;
    }
    return _running = _runSync(initial: initial).whenComplete(() {
      _running = null;
    });
  }

  Future<void> _runSync({bool initial = false}) async {
    if (_coalesce.syncing) {
      _coalesce.markQueuedIfBusy();
      return;
    }
    if (!await isOnline) {
      _armReachabilityRetry();
      return;
    }
    if (!isActive || !_coalesce.tryEnter()) return;

    final started = DateTime.now().toUtc();
    final pendingStart = await _db.pendingCount();
    addSyncStartBreadcrumb(pendingCount: pendingStart);

    try {
      await tracedOp('sync.now', 'sync', () async {
        Object? pullError;
        do {
          _coalesce.clearQueued();
          // Push local bills even when pull fails (embed/schema errors used
          // to abort the whole pass and leave new bills queued forever).
          try {
            await _puller.pull();
            pullError = null;
          } catch (e, st) {
            pullError = e;
            AppLog.warn('sync pull failed; continuing with push', e, st, {
              'phase': 'sync_pull',
            });
          }
          if (initial) {
            AppLog.info(
              'initial_sync_pull_complete',
              extras: {'bootstrapIncomplete': _puller.bootstrapIncomplete},
            );
          }
          final uploaded = await _pusher.push();
          if (uploaded > 0) {
            try {
              await _puller.pull();
              pullError = null;
            } catch (e, st) {
              pullError = e;
              AppLog.warn('sync pull after push failed', e, st, {
                'phase': 'sync_pull_after_push',
              });
            }
          }
          if (pullError != null) {
            _armReachabilityRetry();
          }
        } while (isActive && _coalesce.shouldRepeat);
        if (!isActive) return;
        await _db.pruneSyncedQueue();
        if (pullError == null) {
          await _db.setMetaValue(
            syncMetaLastSuccessAt,
            DateTime.now().toUtc().toIso8601String(),
          );
          _clearReachabilityRetry();
        }
      });
    } catch (e, st) {
      AppLog.warn('sync failed; will retry', e, st, {'phase': 'sync_now'});
      _armReachabilityRetry();
      rethrow;
    } finally {
      final duration = DateTime.now().toUtc().difference(started);
      final pendingEnd = await _db.pendingCount();
      final retryableEnd = await _db.retryableCount();
      final failedEnd = await _db.failedCount();
      final outcome = syncCompletionOutcome(
        retryableCount: retryableEnd,
        failedCount: failedEnd,
      );
      addSyncEndBreadcrumb(
        duration: duration,
        pendingCount: pendingEnd,
        failedCount: failedEnd,
        retryableCount: retryableEnd,
        outcome: outcome,
        bootstrapIncomplete: _puller.bootstrapIncomplete,
      );
      AppLog.info(
        'sync_complete',
        extras: {
          'durationMs': duration.inMilliseconds,
          'outcome': outcome,
          'pendingCount': pendingEnd,
          'retryableCount': retryableEnd,
          'failedCount': failedEnd,
          'bootstrapIncomplete': _puller.bootstrapIncomplete,
          'initial': initial,
        },
      );
      _coalesce.end();
    }
  }

  String newId() => _uuid.v4();
}
