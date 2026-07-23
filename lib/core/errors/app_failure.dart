import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_localizations.dart';

/// Structured app-level failure for UI mapping.
///
/// Prefer throwing / catching [AppFailure] (or converting via [AppFailure.from])
/// instead of swallowing errors into a generic snackbar.
///
/// Avoids `dart:io` so this file stays web-safe.
sealed class AppFailure implements Exception {
  const AppFailure({this.detail});

  /// Optional technical detail (RPC message, Postgrest message, etc.).
  final String? detail;

  static AppFailure from(Object error) {
    if (error is AppFailure) return error;

    if (error is AuthException) {
      return AppFailure.permission(detail: error.message);
    }

    if (error is PostgrestException) {
      final code = error.code;
      final message = error.message;
      if (code == '42501' || message.toLowerCase().contains('forbidden')) {
        return AppFailure.permission(detail: message);
      }
      if (code == '23505') {
        return AppFailure.conflict(detail: message);
      }
      // RPC `raise exception '...'` surfaces as PostgrestException.
      if (_looksLikeValidation(message)) {
        return AppFailure.validation(detail: message);
      }
      return AppFailure.unknown(detail: message);
    }

    if (error is TimeoutException || _looksLikeNetwork(error)) {
      return AppFailure.network(detail: error.toString());
    }

    return AppFailure.unknown(detail: error.toString());
  }

  static bool _looksLikeNetwork(Object error) {
    final text = error.toString();
    return text.contains('SocketException') ||
        text.contains('HandshakeException') ||
        text.contains('HttpException') ||
        text.contains('ClientException') ||
        text.contains('Failed host lookup') ||
        text.contains('Connection refused') ||
        text.contains('Network is unreachable') ||
        text.contains('XMLHttpRequest');
  }

  static bool _looksLikeValidation(String message) {
    final lower = message.toLowerCase();
    return lower.contains('required') ||
        lower.contains('must be') ||
        lower.contains('out of range') ||
        lower.contains('mismatch') ||
        lower.contains('not found') ||
        lower.contains('invalid');
  }

  String message(AppLocalizations l10n) {
    return switch (this) {
      AppFailureNetwork() => l10n.errorNetwork,
      AppFailurePermission(:final detail) =>
        detail?.isNotEmpty == true ? detail! : l10n.errorPermission,
      AppFailureValidation(:final detail) =>
        detail?.isNotEmpty == true ? detail! : l10n.errorValidation,
      AppFailureConflict(:final detail) =>
        detail?.isNotEmpty == true ? detail! : l10n.errorConflict,
      AppFailureNotConfigured() => l10n.errorNotConfigured,
      AppFailureUnknown() => l10n.actionFailed,
    };
  }

  const factory AppFailure.network({String? detail}) = AppFailureNetwork;
  const factory AppFailure.permission({String? detail}) = AppFailurePermission;
  const factory AppFailure.validation({String? detail}) = AppFailureValidation;
  const factory AppFailure.conflict({String? detail}) = AppFailureConflict;
  const factory AppFailure.notConfigured({String? detail}) =
      AppFailureNotConfigured;
  const factory AppFailure.unknown({String? detail}) = AppFailureUnknown;

  @override
  String toString() => '$runtimeType${detail != null ? ': $detail' : ''}';
}

final class AppFailureNetwork extends AppFailure {
  const AppFailureNetwork({super.detail});
}

final class AppFailurePermission extends AppFailure {
  const AppFailurePermission({super.detail});
}

final class AppFailureValidation extends AppFailure {
  const AppFailureValidation({super.detail});
}

final class AppFailureConflict extends AppFailure {
  const AppFailureConflict({super.detail});
}

final class AppFailureNotConfigured extends AppFailure {
  const AppFailureNotConfigured({super.detail});
}

final class AppFailureUnknown extends AppFailure {
  const AppFailureUnknown({super.detail});
}
