import '../errors/app_failure.dart';
import '../l10n/app_localizations.dart';
import '../utils/auth_errors.dart';

/// Runs an inline form submit, mapping failures to a field-level [error] string.
///
/// Returns `true` on success. Callers should update loading/error state via
/// [onState] (typically inside [setState]).
Future<bool> runInlineFormAction({
  required Future<void> Function() action,
  required void Function({required bool loading, String? error}) onState,
  required bool Function() mounted,
  required AppLocalizations l10n,
  String Function(Object error, AppLocalizations l10n)? mapError,
}) async {
  onState(loading: true, error: null);
  String? error;
  try {
    await action();
    return true;
  } catch (e) {
    if (mounted()) {
      error =
          mapError?.call(e, l10n) ?? AppFailure.from(e).message(l10n);
      onState(loading: true, error: error);
    }
    return false;
  } finally {
    if (mounted()) onState(loading: false, error: error);
  }
}

/// Auth-specific mapper for login/register inline errors.
String mapAuthInlineError(Object error, AppLocalizations l10n) =>
    localizeAuthError(error, l10n);
