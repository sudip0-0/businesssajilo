import '../../data/repositories/auth_repository.dart';
import '../l10n/app_localizations.dart';

/// Maps auth/API exceptions to localized user-facing messages.
String localizeAuthError(Object error, AppLocalizations l10n) {
  if (error is AccountDeactivatedException) {
    return l10n.accountDeactivated;
  }
  final msg = error.toString().toLowerCase();
  if (msg.contains('invalid login credentials') ||
      msg.contains('invalid email or password')) {
    return l10n.invalidCredentials;
  }
  if (msg.contains('user already registered') ||
      msg.contains('already been registered')) {
    return l10n.emailAlreadyRegistered;
  }
  if (msg.contains('password') && msg.contains('weak')) {
    return l10n.weakPassword;
  }
  if (msg.contains('network') ||
      msg.contains('socket') ||
      msg.contains('connection')) {
    return l10n.networkError;
  }
  return l10n.somethingWentWrong;
}
