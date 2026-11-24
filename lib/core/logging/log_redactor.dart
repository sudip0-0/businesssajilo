/// Redacts credentials, tokens, and common PII before text or structured
/// extras leave the client via logs or Sentry telemetry.
abstract final class LogRedactor {
  static final _jwtPattern = RegExp(
    r'eyJ[A-Za-z0-9_-]{8,}\.eyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}',
  );
  static final _bearerPattern = RegExp(
    r'\b(Bearer|Basic)\s+[A-Za-z0-9._~+/=-]{8,}',
    caseSensitive: false,
  );
  static final _secretParamPattern = RegExp(
    r'''\b(apikey|api_key|access_token|refresh_token|password|passwd|secret|token|authorization|cookie)\s*([=:])\s*(?!(?:Bearer|Basic)\s+\[REDACTED\])([^\s,&;"'\}\]]+)''',
    caseSensitive: false,
  );
  static final _emailPattern = RegExp(
    r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b',
  );
  // Matches Nepali/international phone numbers (e.g. +97798XXXXXXXX or 98XXXXXXXX).
  static final _phonePattern = RegExp(
    r'(?<!\w)(?:\+?977[-\s]?)?(?:9[6-9]\d{8}|0\d{1,2}[-\s]?\d{6,7})(?!\w)',
  );

  static const _sensitiveKeySubstrings = <String>[
    'password',
    'passwd',
    'secret',
    'token',
    'apikey',
    'api_key',
    'authorization',
    'cookie',
    'email',
    'phone',
  ];

  /// Redacts sensitive patterns from arbitrary log text.
  static String redactText(String input) {
    if (input.isEmpty) return input;
    var out = input.replaceAll(_jwtPattern, '[REDACTED_JWT]');
    out = out.replaceAllMapped(
      _bearerPattern,
      (m) => '${m.group(1)} [REDACTED]',
    );
    out = out.replaceAllMapped(
      _secretParamPattern,
      (m) => '${m.group(1)}${m.group(2)}[REDACTED]',
    );
    out = out.replaceAll(_emailPattern, '[REDACTED_EMAIL]');
    out = out.replaceAll(_phonePattern, '[REDACTED_PHONE]');
    return out;
  }

  /// Redacts a structured map recursively, masking values under sensitive keys
  /// and running [redactText] over string values.
  static Map<String, dynamic> redactMap(Map<String, dynamic> input) {
    final result = <String, dynamic>{};
    for (final entry in input.entries) {
      if (_isSensitiveKey(entry.key)) {
        result[entry.key] = '[REDACTED]';
      } else {
        result[entry.key] = redactValue(entry.value);
      }
    }
    return result;
  }

  static dynamic redactValue(dynamic value) {
    if (value == null || value is num || value is bool) return value;
    if (value is String) return redactText(value);
    if (value is Map) {
      return redactMap(value.map((k, v) => MapEntry(k.toString(), v)));
    }
    if (value is Iterable) {
      return value.map(redactValue).toList();
    }
    return redactText(value.toString());
  }

  static bool _isSensitiveKey(String key) {
    final lower = key.toLowerCase();
    for (final s in _sensitiveKeySubstrings) {
      if (lower.contains(s)) return true;
    }
    return false;
  }
}
