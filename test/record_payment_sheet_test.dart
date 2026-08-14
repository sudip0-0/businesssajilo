import 'package:businesssajilo/core/l10n/app_localizations.dart';
import 'package:businesssajilo/features/customers/record_payment_sheet.dart';
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

  testWidgets('record payment sheet requires amount', (tester) async {
    await tester.pumpWidget(
      wrap(
        const RecordPaymentSheet(customerId: 'c1', customerName: 'Ram Store'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Amount is required'), findsOneWidget);
  });

  testWidgets('record payment sheet rejects zero amount', (tester) async {
    await tester.pumpWidget(
      wrap(
        const RecordPaymentSheet(customerId: 'c1', customerName: 'Ram Store'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '0');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Amount must be greater than zero'), findsOneWidget);
  });

  testWidgets('record payment sheet focuses payment amount', (tester) async {
    await tester.pumpWidget(
      wrap(
        const RecordPaymentSheet(customerId: 'c1', customerName: 'Ram Store'),
      ),
    );
    await tester.pump();
    await tester.pump();

    final amountField = tester.widget<EditableText>(
      find.byType(EditableText).first,
    );
    expect(amountField.focusNode.hasFocus, isTrue);
  });

  testWidgets('payment method opens a sheet picker, not an overlay', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const RecordPaymentSheet(customerId: 'c1', customerName: 'Ram Store'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cheque'), findsNothing);

    await tester.tap(find.text('Cash'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pumpAndSettle();

    expect(find.text('Cheque'), findsOneWidget);
  });
}
