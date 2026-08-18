import 'package:businesssajilo/core/l10n/app_localizations.dart';
import 'package:businesssajilo/domain/models/product.dart';
import 'package:businesssajilo/features/billing/bill_draft_line.dart';
import 'package:businesssajilo/features/billing/bill_form_line_editor.dart';
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

  BillDraftLine line() {
    return BillDraftLine(
      product: const Product(
        id: 'p9',
        businessId: 'biz',
        name: 'Product 09',
        referencePrice: 41000,
        stockCached: 981,
      ),
      qty: 1,
      rate: 41000,
      discount: 1000,
    );
  }

  testWidgets('new line hides rate, price subtitle, and line total', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        BillFormLineEditor(line: line(), onChanged: () {}, onRemove: () {}),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Product 09'), findsOneWidget);
    expect(find.text('Available 981'), findsOneWidget);
    expect(find.text('रू 410'), findsNothing);
    expect(find.text('Line total'), findsNothing);
    expect(find.text('Rate (रू)'), findsNothing);
    expect(find.text('Line discount (रू)'), findsNothing);
    expect(find.text('रू 400'), findsOneWidget);
  });

  testWidgets('expanding a line shows rate and discount, not line total', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        BillFormLineEditor(line: line(), onChanged: () {}, onRemove: () {}),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();

    expect(find.text('Rate (रू)'), findsOneWidget);
    expect(find.text('Line discount (रू)'), findsOneWidget);
    expect(find.text('Line total'), findsNothing);
    expect(find.text('Available 981'), findsOneWidget);
  });
}
