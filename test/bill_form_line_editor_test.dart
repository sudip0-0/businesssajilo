import 'package:businesssajilo/core/l10n/app_localizations.dart';
import 'package:businesssajilo/domain/models/product.dart';
import 'package:businesssajilo/features/billing/bill_draft_line.dart';
import 'package:businesssajilo/features/billing/bill_form_line_editor.dart';
import 'package:businesssajilo/features/billing/bill_summary.dart';
import 'package:businesssajilo/features/billing/bill_form_draft.dart';
import 'package:businesssajilo/features/billing/bill_form_validation.dart';
import 'package:businesssajilo/features/inventory/product_form_screen.dart';
import 'package:businesssajilo/web/features/billing/web_bill_form_line_table.dart';
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

  testWidgets('invalid line money blocks save and can be corrected', (
    tester,
  ) async {
    final draft = BillFormDraft()..lines.add(line());
    await tester.pumpWidget(
      wrap(
        StatefulBuilder(
          builder: (context, setState) => BillFormLineEditor(
            line: draft.lines.single,
            initiallyExpanded: true,
            onChanged: () => setState(() {}),
            onRemove: () {},
          ),
        ),
      ),
    );
    for (final index in [0, 1]) {
      await tester.enterText(find.byType(TextFormField).at(index), '1.001');
      await tester.pump();
      expect(validateBillForm(draft), isNotNull);
      expect(find.text('Enter a valid number'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).at(index),
        index == 0 ? '410.29' : '10.25',
      );
      await tester.pump();
      expect(validateBillForm(draft), isNull);
      expect(find.text('Enter a valid number'), findsNothing);
    }
  });

  testWidgets('expanded rate and discount retain exact paisa', (tester) async {
    final draftLine = line()
      ..rate = 41029
      ..discount = 1025;
    await tester.pumpWidget(
      wrap(
        BillFormLineEditor(
          line: draftLine,
          onChanged: () {},
          onRemove: () {},
          initiallyExpanded: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('410.29'), findsOneWidget);
    expect(find.text('10.25'), findsOneWidget);
    expect(find.text('रू 400.04'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, '410.29');
    expect(draftLine.rate, 41029);
  });

  testWidgets('web line rate survives rebuild without losing paisa', (
    tester,
  ) async {
    final draftLine = line()..rate = 41029;
    Widget row() => wrap(
      Builder(
        builder: (context) => WebBillItemRow(
          index: 0,
          line: draftLine,
          l10n: AppLocalizations.of(context),
          onChanged: () {},
          onRemove: () {},
        ),
      ),
    );
    await tester.pumpWidget(row());
    await tester.pumpAndSettle();
    expect(find.text('410.29'), findsOneWidget);
    draftLine.rate = 51035;
    await tester.pumpWidget(row());
    await tester.pumpAndSettle();
    expect(find.text('510.35'), findsOneWidget);
    expect(find.text('रू 500.35'), findsOneWidget);
  });

  testWidgets('web invalid rate remains invalid after rebuild and corrects', (
    tester,
  ) async {
    final draft = BillFormDraft()..lines.add(line());
    Widget row() => wrap(
      Builder(
        builder: (context) => WebBillItemRow(
          index: 0,
          line: draft.lines.single,
          l10n: AppLocalizations.of(context),
          onChanged: () {},
          onRemove: () {},
        ),
      ),
    );
    await tester.pumpWidget(row());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '1.001');
    await tester.pumpWidget(row());
    await tester.pumpAndSettle();
    expect(find.text('1.001'), findsOneWidget);
    expect(find.text('Enter a valid number'), findsOneWidget);
    expect(validateBillForm(draft), isNotNull);
    await tester.enterText(find.byType(TextField).last, '410.29');
    await tester.pumpAndSettle();
    expect(validateBillForm(draft), isNull);
    expect(find.text('Enter a valid number'), findsNothing);
  });

  testWidgets('product edit prefills retain both price fractions', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const ProductFormScreen(
          product: Product(
            id: 'p1',
            businessId: 'b1',
            name: 'Rice',
            costPrice: 10029,
            referencePrice: 20035,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final texts = tester
        .widgetList<EditableText>(find.byType(EditableText))
        .map((field) => field.controller.text);
    expect(texts, contains('रू 100.29'));
    expect(texts, contains('रू 200.35'));
  });

  testWidgets('bill summary keeps subtotal discount and total fractions', (
    tester,
  ) async {
    final controller = TextEditingController(text: '10.25');
    await tester.pumpWidget(
      wrap(
        BillSummary(
          itemsTotal: 41029,
          billDiscountController: controller,
          grandTotal: 40004,
          onDiscountChanged: () {},
          style: BillSummaryStyle.checkout,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('रू 410.29'), findsOneWidget);
    expect(find.text('- रू 10.25'), findsOneWidget);
    expect(find.text('रू 400.04'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('new line hides rate, price subtitle, and line total', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(BillFormLineEditor(line: line(), onChanged: () {}, onRemove: () {})),
    );
    await tester.pumpAndSettle();

    expect(find.text('Product 09'), findsOneWidget);
    expect(find.text('Available 981'), findsOneWidget);
    expect(find.text('रू 410'), findsNothing);
    expect(find.text('Line total'), findsNothing);
    expect(find.text('Rate (रू)'), findsNothing);
    expect(find.text('Line discount (रू)'), findsNothing);
    expect(find.text('रू 400.00'), findsOneWidget);
  });

  testWidgets('expanding a line shows rate and discount, not line total', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(BillFormLineEditor(line: line(), onChanged: () {}, onRemove: () {})),
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
