/// Build-time environment configuration.
///
/// Pass values with:
/// flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
abstract final class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');

  static const firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
  static const firebaseMessagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
  );
  static const firebaseVapidKey = String.fromEnvironment('FIREBASE_VAPID_KEY');

  /// Optional Sentry DSN. When empty, crash reporting is a no-op.
  static const sentryDsn = String.fromEnvironment('SENTRY_DSN');

  /// Sentry performance tracing sample rate (0–1). Default 0.1 in prod.
  static double get sentryTracesSampleRate {
    const raw = String.fromEnvironment(
      'SENTRY_TRACES_SAMPLE_RATE',
      defaultValue: '0.1',
    );
    return double.tryParse(raw) ?? 0.1;
  }

  /// Integration tests on desktop use the web shell when true.
  static const forceWebUi = bool.fromEnvironment('FORCE_WEB_UI');

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static bool get isFirebaseConfigured =>
      firebaseApiKey.isNotEmpty &&
      firebaseAppId.isNotEmpty &&
      firebaseMessagingSenderId.isNotEmpty &&
      firebaseProjectId.isNotEmpty;

  static bool get hasSentry => sentryDsn.isNotEmpty;
}
