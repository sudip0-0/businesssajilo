import 'package:businesssajilo/core/invoicing/invoice_paper_size.dart';
import 'package:businesssajilo/core/l10n/app_localizations.dart';
import 'package:businesssajilo/features/billing/invoice_paper_size_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget home) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );
  }

  testWidgets('paper size picker returns A4 when tapped', (tester) async {
    InvoicePaperSize? picked;
    await tester.pumpWidget(
      wrap(
        Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  picked = await showInvoicePaperSizePicker(
                    context,
                    title: 'Copy bill as image',
                  );
                },
                child: const Text('open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('A4'), findsOneWidget);
    expect(find.text('A5'), findsOneWidget);

    await tester.tap(find.text('A4'));
    await tester.pumpAndSettle();

    expect(picked, InvoicePaperSize.a4);
  });

  testWidgets('paper size picker runs onSelected before closing', (
    tester,
  ) async {
    InvoicePaperSize? selected;
    await tester.pumpWidget(
      wrap(
        Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () {
                  showInvoicePaperSizePicker(
                    context,
                    title: 'Copy bill as image',
                    onSelected: (size) async {
                      selected = size;
                    },
                  );
                },
                child: const Text('open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('A5'));
    await tester.pumpAndSettle();

    expect(selected, InvoicePaperSize.a5);
    expect(find.text('A5'), findsNothing);
  });
}
