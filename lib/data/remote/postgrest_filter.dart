/// Sanitizes user-supplied search text before interpolating into a PostgREST
/// `.or(...)` `ilike` filter so filter-grammar metacharacters cannot break or
/// inject extra predicates.
String sanitizePostgrestOrIlikeQuery(String raw) {
  final cleaned = raw.trim().replaceAll(RegExp(r'[,()\\"\x27*%_]'), '').trim();
  return cleaned;
}
