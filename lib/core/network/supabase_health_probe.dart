import 'dart:async';
import 'dart:io';

import '../config/env.dart';

/// Result of probing Supabase Auth `/auth/v1/health`.
enum HealthProbeResult {
  ok,
  timeout,
  serverError,
  unreachable,
}

/// Lightweight GET against Supabase Auth health endpoint.
///
/// Used by sync and online-only flows (e.g. credit notes) instead of raw
/// connectivity checks that false-positive on captive portals.
Future<HealthProbeResult> probeSupabaseHealth({
  Duration timeout = const Duration(seconds: 3),
}) async {
  final base = Env.supabaseUrl;
  if (base.isEmpty) return HealthProbeResult.unreachable;

  final uri = Uri.parse('$base/auth/v1/health');
  final client = HttpClient()..connectionTimeout = timeout;
  try {
    final request = await client.getUrl(uri).timeout(timeout);
    final response = await request.close().timeout(timeout);
    await response.drain<void>();
    if (response.statusCode >= 500) return HealthProbeResult.serverError;
    if (response.statusCode >= 400) return HealthProbeResult.unreachable;
    return HealthProbeResult.ok;
  } on TimeoutException {
    return HealthProbeResult.timeout;
  } catch (_) {
    return HealthProbeResult.unreachable;
  } finally {
    client.close(force: true);
  }
}

/// True when the Supabase host responds with a non-5xx health check.
Future<bool> isSupabaseReachable({
  Duration timeout = const Duration(seconds: 3),
}) async {
  final result = await probeSupabaseHealth(timeout: timeout);
  return result == HealthProbeResult.ok;
}
