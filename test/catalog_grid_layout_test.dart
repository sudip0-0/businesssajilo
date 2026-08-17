import 'package:businesssajilo/core/l10n/app_localizations.dart';
import 'package:businesssajilo/domain/models/catalog_product.dart';
import 'package:businesssajilo/features/orders/catalog_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CatalogScreen grid lays out without assertion', (tester) async {
    final products = List.generate(
      8,
      (i) => CatalogProduct(
        id: 'p$i',
        businessId: 'b1',
        name: 'Product $i',
        unit: 'pcs',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [catalogListProvider.overrideWith((ref) async => products)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: CatalogScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Product 0'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
  });
}
