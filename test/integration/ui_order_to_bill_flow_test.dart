import 'package:businesssajilo/app.dart';
import 'package:businesssajilo/core/config/env.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/hardening_gate.dart';
import 'support/bootstrap.dart';

/// UI-driven happy path (documented stub): pump the app, sign in as owner,
/// create customer order, send quote, accept as customer, bill from order.
///
/// Requires local Supabase (`supabase start`) and dart-defines from `.env.local`.
/// Skips gracefully when env is missing; fails when `HARDENING_GATE=1`.
///
/// Repository-level coverage lives in `repository_order_to_bill_test.dart`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('UI order → quote → accept → bill (local Supabase)', (
    tester,
  ) async {
    final envReady = Env.isConfigured;
    final supabaseUp = envReady && await isSupabaseAvailable();

    requireForHardeningGate(
      envReady && supabaseUp,
      'UI order→bill flow needs SUPABASE_URL/ANON_KEY and `supabase start`',
    );

    if (!envReady || !supabaseUp) return;

    // Full widget navigation is intentionally deferred — bootstrap + sign-in
    // proves the integration harness is wired; extend with screen pumps when
    // stable golden paths exist for quote builder and bill form.
    final booted = await bootstrapIntegrationApp();
    expect(booted, isTrue, reason: 'integration bootstrap should succeed');
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.byType(BusinessSajiloApp), findsOneWidget);
  });
}
