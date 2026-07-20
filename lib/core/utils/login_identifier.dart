/// Phone-based login support.
///
/// Members created without a real email get a synthetic auth email derived
/// from their normalized phone number. The format must stay in sync with
/// `supabase/functions/create-member/index.ts`.
library;

const phoneLoginDomain = 'phone.businesssajilo.app';

final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Normalizes a Nepali mobile number to `+9779XXXXXXXXX`.
///
/// Accepts `98XXXXXXXX`, `098XXXXXXXX`, `977 98XXXXXXXX`, `+977-98XXXXXXXX`,
/// with spaces/dashes/parentheses. Returns null when the input is not a
/// valid 10-digit Nepali mobile number starting with 9.
String? normalizeNepalPhone(String raw) {
  var digits = raw.replaceAll(RegExp(r'[\s\-()]'), '');
  if (digits.startsWith('+')) digits = digits.substring(1);
  String local;
  if (digits.startsWith('977')) {
    local = digits.substring(3);
  } else if (RegExp(r'^0\d{9,}$').hasMatch(digits)) {
    local = digits.substring(1);
  } else {
    local = digits;
  }
  if (!RegExp(r'^9\d{9}$').hasMatch(local)) return null;
  return '+977$local';
}

/// Synthetic auth email for a normalized phone (`+9779841XXXXXX`).
String phoneLoginEmail(String normalizedPhone) {
  return '${normalizedPhone.substring(4)}@$phoneLoginDomain';
}

/// Maps a sign-in identifier (email address or phone number) to the email
/// used for Supabase password auth. Unrecognized input is returned trimmed
/// so auth fails with the normal invalid-credentials error.
String loginEmailForIdentifier(String input) {
  final trimmed = input.trim();
  // Auth emails are stored lowercased (create-member / GoTrue); match that.
  if (trimmed.contains('@')) return trimmed.toLowerCase();
  final phone = normalizeNepalPhone(trimmed);
  if (phone != null) return phoneLoginEmail(phone);
  return trimmed;
}

/// Whether [input] looks like a valid sign-in identifier (email or phone).
bool isValidLoginIdentifier(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return false;
  if (trimmed.contains('@')) return _emailRegex.hasMatch(trimmed);
  return normalizeNepalPhone(trimmed) != null;
}
