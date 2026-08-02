import 'dart:io';

import 'package:businesssajilo/app.dart';
import 'package:businesssajilo/core/config/env.dart';
import 'package:businesssajilo/main.dart' show ConfigErrorApp;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

bool _supabaseReady = false;

/// Quick health check before initializing Supabase in integration tests.
Future<bool> isSupabaseAvailable() async {
  if (!Env.isConfigured) return false;
  try {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
    final request = await client.getUrl(Uri.parse(Env.supabaseUrl));
    final response = await request.close();
    final ok = response.statusCode >= 200 && response.statusCode < 500;
    client.close(force: true);
    return ok;
  } catch (_) {
    return false;
  }
}

/// Boots the app for integration tests with a pre-authenticated owner session.
Future<bool> bootstrapIntegrationApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!Env.isConfigured) {
    runApp(const ConfigErrorApp());
    return false;
  }

  try {
    if (!_supabaseReady) {
      await Supabase.initialize(
        url: Env.supabaseUrl,
        publishableKey: Env.supabaseAnonKey,
      );
      _supabaseReady = true;
    }

    const email = String.fromEnvironment(
      'E2E_EMAIL',
      defaultValue: 'e2e-owner@test.com',
    );
    const password = String.fromEnvironment(
      'E2E_PASSWORD',
      defaultValue: 'password123',
    );

    await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    runApp(const ProviderScope(child: BusinessSajiloApp()));
    return true;
  } catch (error, stack) {
    debugPrint('Integration bootstrap failed: $error\n$stack');
    return false;
  }
}
