import 'package:businesssajilo/core/l10n/app_localizations.dart';
import 'package:businesssajilo/core/ui/locale_toggle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:businesssajilo/core/layout/adaptive_scaffold.dart';

const _l10nDelegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

void main() {
  testWidgets('app bar title ellipsizes and nav bar is even height', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: _l10nDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AdaptiveScaffold(
          selectedIndex: 0,
          onDestinationSelected: (_) {},
          titles: const ['Dashboard'],
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              label: 'Inventory',
            ),
            NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              label: 'Customers',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              label: 'Billing',
            ),
            NavigationDestination(
              icon: Icon(Icons.more_horiz_outlined),
              label: 'More',
            ),
          ],
          actions: const [
            IconButton(icon: Icon(Icons.search), onPressed: null),
          ],
          body: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LocaleToggle), findsNothing);
    expect(find.text('Dashboard'), findsWidgets);
    final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navBar.height, 64);
    expect(navBar.labelBehavior, NavigationDestinationLabelBehavior.alwaysShow);
  });
}
