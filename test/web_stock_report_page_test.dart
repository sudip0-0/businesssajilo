import 'package:businesssajilo/core/l10n/app_localizations.dart';
import 'package:businesssajilo/domain/models/stock_valuation_row.dart';
import 'package:businesssajilo/features/reports/providers.dart';
import 'package:businesssajilo/web/features/reports/web_stock_report_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('WebStockReportPage shows products and filters low stock', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stockValuationProvider(false).overrideWith(
            (ref) async => [
              const StockValuationRow(
                productId: 'p1',
                name: 'Cola',
                stockCached: 2,
                costPrice: 3000,
                valuation: 6000,
                isLowStock: true,
              ),
              const StockValuationRow(
                productId: 'p2',
                name: 'Chips',
                stockCached: 40,
                costPrice: 1000,
                valuation: 40000,
                isLowStock: false,
              ),
            ],
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: WebStockReportPage()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Stock valuation'), findsWidgets);
    expect(find.text('Cola'), findsWidgets);
    expect(find.text('Chips'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Low'));
    await tester.pumpAndSettle();

    expect(find.text('Cola'), findsWidgets);
    expect(find.text('Chips'), findsNothing);
  });

  testWidgets('WebStockReportPage honors status=low deep link', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stockValuationProvider(false).overrideWith(
            (ref) async => [
              const StockValuationRow(
                productId: 'p1',
                name: 'Cola',
                stockCached: 2,
                costPrice: 3000,
                valuation: 6000,
                isLowStock: true,
              ),
              const StockValuationRow(
                productId: 'p2',
                name: 'Chips',
                stockCached: 40,
                costPrice: 1000,
                valuation: 40000,
              ),
            ],
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: WebStockReportPage(initialStatus: 'low')),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Low Stock'), findsWidgets);
    expect(find.text('Chips'), findsNothing);
    expect(find.text('Cola'), findsWidgets);
  });
}
