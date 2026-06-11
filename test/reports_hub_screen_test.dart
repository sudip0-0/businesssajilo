import 'package:businesssajilo/core/l10n/app_localizations.dart';
import 'package:businesssajilo/features/reports/reports_hub_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('reports hub shows three report tiles', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: ReportsHubScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sales summary'), findsOneWidget);
    expect(find.text('Dues aging'), findsOneWidget);
    expect(find.text('Stock valuation'), findsOneWidget);
    expect(find.byType(ListTile), findsNWidgets(3));
  });
}
