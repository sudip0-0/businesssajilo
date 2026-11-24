import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../config/env.dart';
import 'log_redactor.dart';

/// Thin app logger. Prints redacted messages in debug builds only; forwards
/// redacted warn/error events to Sentry when [Env.hasSentry] is true.
abstract final class AppLog {
  static void debug(String message) {
    if (kDebugMode) {
      debugPrint(LogRedactor.redactText(message));
    }
  }

  static void info(String message, {Map<String, dynamic>? extras}) {
    final safeMessage = LogRedactor.redactText(message);
    if (kDebugMode) {
      debugPrint('INFO: $safeMessage');
    }
    if (!Env.hasSentry) return;
    final safeExtras = extras != null && extras.isNotEmpty
        ? LogRedactor.redactMap(extras)
        : null;
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: safeMessage,
        level: SentryLevel.info,
        data: safeExtras,
      ),
    );
  }

  static void warn(
    String message, [
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extras,
  ]) {
    final safeMessage = LogRedactor.redactText(message);
    final safeError = error != null
        ? LogRedactor.redactText(error.toString())
        : null;
    if (kDebugMode) {
      debugPrint(
        'WARN: $safeMessage${safeError != null ? ' — $safeError' : ''}',
      );
    }
    if (!Env.hasSentry) return;
    final safeExtras = extras != null && extras.isNotEmpty
        ? LogRedactor.redactMap(extras)
        : null;
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: safeMessage,
        level: SentryLevel.warning,
        data: {'error': ?safeError, ...?safeExtras},
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
    final safeMessage = LogRedactor.redactText(message);
    final safeError = error != null
        ? LogRedactor.redactText(error.toString())
        : null;
    if (kDebugMode) {
      debugPrint(
        'ERROR: $safeMessage${safeError != null ? ' — $safeError' : ''}',
      );
    }
    if (!Env.hasSentry) return;
    final safeExtras = extras != null && extras.isNotEmpty
        ? LogRedactor.redactMap(extras)
        : null;
    void applyScope(Scope scope) {
      if (safeExtras == null) return;
      for (final entry in safeExtras.entries) {
        scope.setContexts(entry.key, {'value': entry.value});
      }
    }

    if (error != null) {
      Sentry.captureException(
        error,
        stackTrace: stackTrace,
        withScope: safeExtras != null ? applyScope : null,
      );
    } else {
      Sentry.captureMessage(
        safeMessage,
        level: SentryLevel.error,
        withScope: safeExtras != null ? applyScope : null,
      );
    }
  }
}
