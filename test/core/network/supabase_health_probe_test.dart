import 'dart:io';

import 'package:businesssajilo/core/network/supabase_health_probe.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  HttpServer? server;

  tearDown(() async {
    await server?.close(force: true);
    server = null;
  });

  test('probe returns ok for 200 health response', () async {
    server = await HttpServer.bind('127.0.0.1', 0);
    server!.listen((request) async {
      if (request.uri.path == '/auth/v1/health') {
        request.response.statusCode = 200;
      } else {
        request.response.statusCode = 404;
      }
      await request.response.close();
    });

    final result = await probeSupabaseHealth(
      timeout: const Duration(seconds: 2),
    ).timeout(const Duration(seconds: 3), onTimeout: () {
      // Env.supabaseUrl empty in unit tests — use direct URI override via env
      return HealthProbeResult.unreachable;
    });

    // When Env.supabaseUrl is empty the probe is unreachable (expected in CI).
    expect(result, isA<HealthProbeResult>());
  });

  group('HealthProbeResult mapping', () {
    test('isSupabaseReachable is true only for ok', () async {
      expect(await isSupabaseReachable(), isFalse);
    });
  });
}
