import 'package:businesssajilo/core/l10n/app_localizations.dart';
import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/domain/models/dues_aging_report.dart';
import 'package:businesssajilo/features/billing/providers.dart';
import 'package:businesssajilo/features/customers/providers.dart';
import 'package:businesssajilo/features/inventory/providers.dart';
import 'package:businesssajilo/features/reports/providers.dart';
import 'package:businesssajilo/features/reports/reports_hub_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('reports hub shows three report tiles', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          salesDailyProvider(ReportRange.week).overrideWith((ref) async => []),
          duesAgingProvider.overrideWith((ref) async => const DuesAgingReport()),
          stockValuationProvider(false).overrideWith((ref) async => []),
          todaysSalesProvider.overrideWith((ref) async => 0),
          totalDuesProvider.overrideWith((ref) async => 0),
          lowStockCountProvider.overrideWith((ref) async => 0),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: ReportsHubScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Business analytics overview'), findsOneWidget);
    expect(find.byType(ListTile), findsNWidgets(3));
    expect(find.widgetWithText(ListTile, 'Sales summary'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Dues aging'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Stock valuation'), findsOneWidget);
  });
}
