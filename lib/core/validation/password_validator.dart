/// Shared password rules — keep in sync with Edge Function checks (8–72).
abstract final class PasswordValidator {
  static const minLength = 8;
  static const maxLength = 72;

  /// Returns an error key hint, or null when valid.
  /// Callers map to l10n (`fieldRequired` / `passwordTooShort` / `passwordTooLong`).
  static PasswordValidationError? validate(String? value) {
    if (value == null || value.isEmpty) {
      return PasswordValidationError.required;
    }
    if (value.length < minLength) return PasswordValidationError.tooShort;
    if (value.length > maxLength) return PasswordValidationError.tooLong;
    return null;
  }
}

enum PasswordValidationError { required, tooShort, tooLong }
