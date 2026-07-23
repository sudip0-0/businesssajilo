import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/env.dart';
import 'core/logging/app_log.dart';
import 'core/notifications/push_service.dart';

Future<void> main() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      if (Env.hasSentry) {
        await SentryFlutter.init((options) {
          options.dsn = Env.sentryDsn;
          options.environment = Env.flavor;
          options.tracesSampleRate = 0.0;
        });
      }

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        AppLog.error(
          'FlutterError',
          error: details.exception,
          stackTrace: details.stack,
        );
      };

      if (!Env.isConfigured) {
        // Misconfigured build: show a clear message instead of a broken app.
        runApp(const ConfigErrorApp());
        return;
      }

      await PushService.init();

      await Supabase.initialize(
        url: Env.supabaseUrl,
        publishableKey: Env.supabaseAnonKey,
      );

      runApp(const ProviderScope(child: BusinessSajiloApp()));
    },
    (error, stack) {
      AppLog.error('Uncaught zone error', error: error, stackTrace: stack);
    },
  );
}

class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.settings_suggest, size: 56, color: Colors.redAccent),
                SizedBox(height: 16),
                Text(
                  'App is not configured.\n'
                  'Run with --dart-define=SUPABASE_URL=... '
                  '--dart-define=SUPABASE_ANON_KEY=...',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
