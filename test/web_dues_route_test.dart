import 'package:businesssajilo/core/l10n/app_localizations.dart';
import 'package:businesssajilo/domain/models/aging_customer_row.dart';
import 'package:businesssajilo/domain/models/dues_aging_report.dart';
import 'package:businesssajilo/features/reports/providers.dart';
import 'package:businesssajilo/web/features/reports/web_dues_aging_page.dart';
import 'package:businesssajilo/web/features/reports/web_reports_hub_page.dart';
import 'package:businesssajilo/web/layout/web_app_shell.dart';
import 'package:businesssajilo/web/layout/web_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

void main() {
  testWidgets('sibling /owner/reports/dues shows dues page', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = GoRouter(
      initialLocation: '/owner/reports/dues',
      routes: [
        ShellRoute(
          builder: (context, state, child) => WebAppShell(
            navItems: [
              const WebNavItem(
                label: 'Reports',
                path: '/owner/reports',
                icon: PhosphorIconsRegular.chartBar,
              ),
            ],
            child: child,
          ),
          routes: [
            GoRoute(
              path: '/owner/reports',
              builder: (_, _) => const WebReportsHubPage(),
            ),
            GoRoute(
              path: '/owner/reports/dues',
              builder: (_, _) => const WebDuesAgingPage(),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          duesAgingProvider.overrideWith(
            (ref) async => DuesAgingReport(
              bucket0to30: 10000,
              customers: [
                AgingCustomerRow(
                  customerId: 'c1',
                  shopName: 'Ram Store',
                  balanceDue: 10000,
                  oldestDueAt: DateTime(2026, 6, 1),
                  ageDays: 10,
                  bucket: '0_30',
                ),
              ],
            ),
          ),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(WebDuesAgingPage), findsOneWidget);
    expect(find.text('Dues aging'), findsWidgets);
    expect(find.text('Ram Store'), findsOneWidget);
    expect(find.byType(WebReportsHubPage), findsNothing);
  });
}
