import 'package:businesssajilo/core/l10n/app_localizations.dart';
import 'package:businesssajilo/data/repositories/stock_repository.dart';
import 'package:businesssajilo/domain/models/product.dart';
import 'package:businesssajilo/domain/models/stock_movement.dart';
import 'package:businesssajilo/features/inventory/product_detail_screen.dart';
import 'package:businesssajilo/features/inventory/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeStockRepository implements StockRepository {
  @override
  Future<List<StockMovement>> listMovements(
    String productId, {
    int offset = 0,
    int limit = 50,
  }) async => const [];

  @override
  Future<StockMovement> adjust({
    required String productId,
    required int qtyDelta,
    required String reason,
    required String createdByMemberId,
  }) => throw UnimplementedError();

  @override
  Future<StockMovement> stockIn({
    required String productId,
    required int qty,
    required String createdByMemberId,
    String? reason,
  }) => throw UnimplementedError();
}

void main() {
  testWidgets('product facts use a compact two-column panel', (tester) async {
    tester.view.physicalSize = const Size(480, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    const product = Product(
      id: 'product-1',
      businessId: 'business-1',
      name: 'Teddy',
      nameNp: 'टेडी',
      sku: 'BS-6E8FB0C3',
      unit: 'piece',
      costPrice: 50000,
      referencePrice: 58000,
      stockCached: 95,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productDetailProvider(
            product.id,
          ).overrideWith((ref) async => product),
          stockRepositoryProvider.overrideWithValue(_FakeStockRepository()),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ProductDetailScreen(
            productId: 'product-1',
            canManageStock: true,
            canEditProduct: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final panel = find.byKey(const Key('product-facts-panel'));
    expect(panel, findsOneWidget);
    expect(tester.getSize(panel).height, lessThan(130));
    expect(find.text('SKU'), findsOneWidget);
    expect(find.text('Unit'), findsOneWidget);
    expect(find.text('Cost price'), findsOneWidget);
    expect(find.text('Reference price'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
