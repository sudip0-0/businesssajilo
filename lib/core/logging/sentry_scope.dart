import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../config/env.dart';
import '../../domain/enums.dart';

/// Route observer for Sentry performance tracing (no-op when DSN is unset).
List<NavigatorObserver> sentryNavigatorObservers() {
  if (!Env.hasSentry) return const [];
  return [SentryNavigatorObserver()];
}

/// Timed operation span for auth, sync, and RPC hot paths.
Future<T> tracedOp<T>(
  String name,
  String operation,
  Future<T> Function() run,
) async {
  if (!Env.hasSentry) return run();
  final span = Sentry.startTransaction(name, operation);
  try {
    return await run();
  } finally {
    await span.finish();
  }
}

/// Configures Sentry user context after session load.
void configureSentrySessionScope({
  required String memberId,
  required Role role,
  required bool syncEnabled,
}) {
  if (!Env.hasSentry) return;
  Sentry.configureScope((scope) {
    scope.setUser(SentryUser(id: memberId));
    scope.setTag('role', role.name);
    scope.setTag('flavor', Env.flavor);
    scope.setTag('sync_enabled', syncEnabled.toString());
  });
}

/// Clears session-scoped tags on logout or tenant switch.
void clearSentrySessionScope() {
  if (!Env.hasSentry) return;
  Sentry.configureScope((scope) {
    scope.setUser(null);
    scope.removeTag('role');
    scope.removeTag('flavor');
    scope.removeTag('sync_enabled');
  });
}

void addSyncStartBreadcrumb({required int pendingCount}) {
  if (!Env.hasSentry) return;
  Sentry.addBreadcrumb(
    Breadcrumb(
      message: 'sync_start',
      category: 'sync',
      level: SentryLevel.info,
      data: {'pending_count': pendingCount},
    ),
  );
}

void addSyncEndBreadcrumb({
  required Duration duration,
  required int pendingCount,
  int failedCount = 0,
  int retryableCount = 0,
  String outcome = 'all_synced',
  bool bootstrapIncomplete = false,
}) {
  if (!Env.hasSentry) return;
  Sentry.addBreadcrumb(
    Breadcrumb(
      message: 'sync_end',
      category: 'sync',
      level: SentryLevel.info,
      data: {
        'duration_ms': duration.inMilliseconds,
        'pending_count': pendingCount,
        'retryable_count': retryableCount,
        'failed_count': failedCount,
        'outcome': outcome,
        'bootstrap_incomplete': bootstrapIncomplete,
      },
    ),
  );
}
