import 'package:businesssajilo/core/l10n/app_localizations.dart';
import 'package:businesssajilo/features/billing/bill_lines_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

const _l10nDelegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

void main() {
  testWidgets('stacked bill lines show full product name at 360px', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: _l10nDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return BillLinesTable(
                    l10n: l10n,
                    lines: const [
                      BillLineView(
                        name: 'Testing Product Name',
                        qty: '2',
                        rate: 'Rs 700',
                        amount: 'Rs 1,400',
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Testing Product Name'), findsOneWidget);
    expect(find.byType(BillLineStackedRow), findsOneWidget);
    expect(find.byType(BillLineRow), findsNothing);
  });

  testWidgets('wide bill lines keep a table row', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: _l10nDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 720,
              child: Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return BillLinesTable(
                    l10n: l10n,
                    lines: const [
                      BillLineView(
                        name: 'Testing Product Name',
                        qty: '2',
                        rate: 'Rs 700',
                        amount: 'Rs 1,400',
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Testing Product Name'), findsOneWidget);
    expect(find.byType(BillLineRow), findsOneWidget);
    expect(find.byType(BillLineStackedRow), findsNothing);
  });
}
