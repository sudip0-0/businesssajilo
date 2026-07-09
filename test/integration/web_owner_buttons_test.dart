import 'package:businesssajilo/core/config/env.dart';
import 'package:businesssajilo/core/l10n/app_localizations_en.dart';
import 'package:businesssajilo/core/testing/integration_keys.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/bootstrap.dart';
import 'support/pump_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late bool supabaseAvailable;

  setUpAll(() async {
    supabaseAvailable = await isSupabaseAvailable();
  });

  group('Owner web button navigation', () {
    Future<bool> startApp(WidgetTester tester) async {
      if (!Env.isConfigured || !supabaseAvailable) return false;
      final ready = await bootstrapIntegrationApp();
      if (!ready) return false;
      useWebViewport(tester);
      await settle(tester);
      return true;
    }

    testWidgets('dashboard New Bill header button opens bill form', (
      tester,
    ) async {
      if (!Env.isConfigured) {
        markTestSkipped('Set SUPABASE_URL and SUPABASE_ANON_KEY dart-defines');
        return;
      }
      if (!supabaseAvailable || !await startApp(tester)) {
        markTestSkipped('Supabase not reachable. Run: supabase start');
        return;
      }

      await pumpUntilFound(
        tester,
        find.byKey(IntegrationKeys.dashboardNewBill),
      );
      await tester.tap(find.byKey(IntegrationKeys.dashboardNewBill));
      await settle(tester);

      expect(find.byKey(IntegrationKeys.billFormCancel), findsOneWidget);
      expect(find.byKey(IntegrationKeys.billFormAddProduct), findsOneWidget);
      final l10n = AppLocalizationsEn();
      expect(find.text(l10n.createNewBill), findsWidgets);
    });

    testWidgets('dashboard Add Product header button opens product form', (
      tester,
    ) async {
      if (!Env.isConfigured) {
        markTestSkipped('Set SUPABASE_URL and SUPABASE_ANON_KEY dart-defines');
        return;
      }
      if (!supabaseAvailable || !await startApp(tester)) {
        markTestSkipped('Supabase not reachable. Run: supabase start');
        return;
      }

      await pumpUntilFound(
        tester,
        find.byKey(IntegrationKeys.dashboardAddProduct),
      );
      await tester.tap(find.byKey(IntegrationKeys.dashboardAddProduct));
      await settle(tester);

      final l10n = AppLocalizationsEn();
      expect(find.text(l10n.addProduct), findsWidgets);
    });

    testWidgets('bill form Cancel returns to billing list', (tester) async {
      if (!Env.isConfigured) {
        markTestSkipped('Set SUPABASE_URL and SUPABASE_ANON_KEY dart-defines');
        return;
      }
      if (!supabaseAvailable || !await startApp(tester)) {
        markTestSkipped('Supabase not reachable. Run: supabase start');
        return;
      }

      await pumpUntilFound(
        tester,
        find.byKey(IntegrationKeys.dashboardNewBill),
      );
      await tester.tap(find.byKey(IntegrationKeys.dashboardNewBill));
      await settle(tester);

      await pumpUntilFound(tester, find.byKey(IntegrationKeys.billFormCancel));
      await tester.tap(find.byKey(IntegrationKeys.billFormCancel));
      await settle(tester);

      expect(find.byKey(IntegrationKeys.billFormCancel), findsNothing);
      expect(
        find.byKey(IntegrationKeys.sidebarNav('/owner/billing')),
        findsOneWidget,
      );
    });

    testWidgets('sidebar Billing nav opens billing list', (tester) async {
      if (!Env.isConfigured) {
        markTestSkipped('Set SUPABASE_URL and SUPABASE_ANON_KEY dart-defines');
        return;
      }
      if (!supabaseAvailable || !await startApp(tester)) {
        markTestSkipped('Supabase not reachable. Run: supabase start');
        return;
      }

      await pumpUntilFound(
        tester,
        find.byKey(IntegrationKeys.sidebarNav('/owner/billing')),
      );
      await tester.tap(
        find.byKey(IntegrationKeys.sidebarNav('/owner/billing')),
      );
      await settle(tester);

      expect(find.byKey(IntegrationKeys.sidebarCreateBill), findsOneWidget);
    });

    testWidgets('sidebar Create New Bill opens bill form', (tester) async {
      if (!Env.isConfigured) {
        markTestSkipped('Set SUPABASE_URL and SUPABASE_ANON_KEY dart-defines');
        return;
      }
      if (!supabaseAvailable || !await startApp(tester)) {
        markTestSkipped('Supabase not reachable. Run: supabase start');
        return;
      }

      await pumpUntilFound(
        tester,
        find.byKey(IntegrationKeys.sidebarCreateBill),
      );
      await tester.tap(find.byKey(IntegrationKeys.sidebarCreateBill));
      await settle(tester);

      expect(find.byKey(IntegrationKeys.billFormCancel), findsOneWidget);
      expect(find.byKey(IntegrationKeys.billFormAddProduct), findsOneWidget);
    });

    testWidgets('bill form Add product focuses product search', (tester) async {
      if (!Env.isConfigured) {
        markTestSkipped('Set SUPABASE_URL and SUPABASE_ANON_KEY dart-defines');
        return;
      }
      if (!supabaseAvailable || !await startApp(tester)) {
        markTestSkipped('Supabase not reachable. Run: supabase start');
        return;
      }

      await pumpUntilFound(
        tester,
        find.byKey(IntegrationKeys.sidebarCreateBill),
      );
      await tester.tap(find.byKey(IntegrationKeys.sidebarCreateBill));
      await settle(tester);

      await pumpUntilFound(
        tester,
        find.byKey(IntegrationKeys.billFormAddProduct),
      );
      await tester.tap(find.byKey(IntegrationKeys.billFormAddProduct));
      await tester.pump();

      expect(tester.binding.focusManager.primaryFocus?.hasFocus, isTrue);
    });
  });
}
