import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../config/env.dart';

/// Thin app logger. Always prints in debug; forwards warn/error to Sentry
/// when [Env.hasSentry] is true.
abstract final class AppLog {
  static void debug(String message) {
    debugPrint(message);
  }

  static void warn(String message, [Object? error, StackTrace? stackTrace]) {
    debugPrint('WARN: $message${error != null ? ' — $error' : ''}');
    if (!Env.hasSentry) return;
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: message,
        level: SentryLevel.warning,
        data: error != null ? {'error': error.toString()} : null,
      ),
    );
    if (error != null) {
      Sentry.captureException(error, stackTrace: stackTrace);
    }
  }

  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extras,
  }) {
    debugPrint('ERROR: $message${error != null ? ' — $error' : ''}');
    if (!Env.hasSentry) return;
    if (extras != null && extras.isNotEmpty) {
      Sentry.configureScope((scope) {
        for (final entry in extras.entries) {
          scope.setContexts(entry.key, {'value': entry.value});
        }
      });
    }
    if (error != null) {
      Sentry.captureException(error, stackTrace: stackTrace);
    } else {
      Sentry.captureMessage(message, level: SentryLevel.error);
    }
  }
}
