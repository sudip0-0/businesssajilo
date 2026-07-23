import 'package:sentry_flutter/sentry_flutter.dart';

import '../config/env.dart';
import '../../domain/enums.dart';

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
        'bootstrap_incomplete': bootstrapIncomplete,
      },
    ),
  );
}
