import 'package:businesssajilo/core/l10n/app_localizations.dart';
import 'package:businesssajilo/features/billing/bill_payment_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('bill payment sheet shows walk-in and paid options', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(const BillPaymentSheet(grandTotal: 10000, initialCustomerId: null)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Walk-in'), findsOneWidget);
    expect(find.text('Paid'), findsOneWidget);
  });

  testWidgets('bill payment sheet shows partial amount field', (tester) async {
    await tester.pumpWidget(wrap(const BillPaymentSheet(grandTotal: 10000)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Partial'));
    await tester.pumpAndSettle();

    expect(find.text('Amount paid'), findsOneWidget);
  });
}
