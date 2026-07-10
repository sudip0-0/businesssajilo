import 'package:businesssajilo/core/l10n/app_localizations.dart';
import 'package:businesssajilo/domain/models/aging_customer_row.dart';
import 'package:businesssajilo/domain/models/dues_aging_report.dart';
import 'package:businesssajilo/features/reports/providers.dart';
import 'package:businesssajilo/web/features/reports/web_dues_aging_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('WebDuesAgingPage shows bucket cards and customers', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final report = DuesAgingReport(
      bucket0to30: 10000,
      bucket31to60: 20000,
      bucket60plus: 5000,
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
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          duesAgingProvider.overrideWith((ref) async => report),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: WebDuesAgingPage()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Dues aging'), findsWidgets);
    expect(find.text('Ram Store'), findsOneWidget);
  });

  testWidgets('WebDuesAgingPage shows empty state when no dues', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          duesAgingProvider.overrideWith(
            (ref) async => const DuesAgingReport(),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: WebDuesAgingPage()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No outstanding dues'), findsOneWidget);
  });
}
