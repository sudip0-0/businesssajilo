import 'package:businesssajilo/core/l10n/app_localizations.dart';
import 'package:businesssajilo/domain/models/customer.dart';
import 'package:businesssajilo/features/customers/providers.dart';
import 'package:businesssajilo/features/orders/providers.dart';
import 'package:businesssajilo/web/features/dashboard/web_customer_dashboard_page.dart';
import 'package:businesssajilo/web/theme/web_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('customer dashboard cards lay out without hasSize assertion', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ownOrderCountProvider.overrideWith((ref) async => 0),
          ownCustomerProvider.overrideWith(
            (ref) async => const Customer(
              id: 'c1',
              businessId: 'b1',
              memberId: 'm1',
              shopName: 'Test Shop',
              balanceDue: 1000000,
            ),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData(extensions: const [WebTokens.light]),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const WebCustomerDashboardPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('MY ORDERS'), findsOneWidget);
    expect(find.text('MY DUES'), findsOneWidget);
  });
}
