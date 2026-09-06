import 'package:businesssajilo/core/l10n/app_localizations.dart';
import 'package:businesssajilo/data/repositories/products_repository.dart';
import 'package:businesssajilo/data/repositories/stock_repository.dart';
import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/domain/models/member.dart';
import 'package:businesssajilo/domain/models/product.dart';
import 'package:businesssajilo/domain/models/session_state.dart';
import 'package:businesssajilo/domain/models/stock_movement.dart';
import 'package:businesssajilo/features/auth/providers/auth_provider.dart';
import 'package:businesssajilo/features/inventory/product_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _OwnerAuth extends AuthController {
  @override
  AsyncValue<SessionState> build() => const AsyncData(
    SessionState(
      member: Member(
        id: 'm1',
        businessId: 'b1',
        authUserId: 'a1',
        role: Role.owner,
        displayName: 'Owner',
      ),
    ),
  );
}

class _NoMember extends AuthController {
  @override
  AsyncValue<SessionState> build() => const AsyncData(SessionState());
}

class _Products implements ProductsRepository {
  int creates = 0;
  bool fail = false;
  @override
  Future<Product> create({
    required String name,
    String? nameNp,
    String? sku,
    required String unit,
    int costPrice = 0,
    int referencePrice = 0,
    int lowStockThreshold = 0,
  }) async {
    creates++;
    if (fail) throw StateError('response lost');
    return Product(
      id: 'p1',
      businessId: 'b1',
      name: name,
      sku: sku,
      unit: unit,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Stock implements StockRepository {
  int calls = 0;
  @override
  Future<StockMovement> stockIn({
    required String productId,
    required int qty,
    required String createdByMemberId,
    String? reason,
  }) async {
    calls++;
    throw StateError('response lost');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('opening stock without a member does not create a product', (
    tester,
  ) async {
    final products = _Products();
    final stock = _Stock();
    final key = GlobalKey<ProductFormScreenState>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(_NoMember.new),
          productsRepositoryProvider.overrideWithValue(products),
          stockRepositoryProvider.overrideWithValue(stock),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: ProductFormScreen(key: key, embedded: true)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Product Name'),
      'Rice',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Initial quantity'),
      '2',
    );
    await key.currentState!.submit();
    await tester.pumpAndSettle();
    expect(products.creates, 0);
    expect(stock.calls, 0);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(ProductFormScreen)),
    );
    expect(find.text(l10n.importMissingMember), findsOneWidget);
  });

  for (final createFails in [false, true]) {
    testWidgets(
      'product form prevents replay after ${createFails ? 'creation' : 'opening stock'} uncertainty',
      (tester) async {
        final products = _Products()..fail = createFails;
        final stock = _Stock();
        final key = GlobalKey<ProductFormScreenState>();
        var saved = 0;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith(_OwnerAuth.new),
              productsRepositoryProvider.overrideWithValue(products),
              stockRepositoryProvider.overrideWithValue(stock),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: ProductFormScreen(
                  key: key,
                  embedded: true,
                  onSaved: (_) => saved++,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        Finder field(String label) => find.widgetWithText(TextFormField, label);
        await tester.enterText(field('Product Name'), 'Rice');
        await tester.enterText(field('Initial quantity'), '2');
        await key.currentState!.submit();
        await tester.pumpAndSettle();
        final l10n = AppLocalizations.of(
          tester.element(find.byType(ProductFormScreen)),
        );
        expect(
          find.text(
            createFails
                ? l10n.importCreateUnconfirmed
                : l10n.importStockUnconfirmed,
          ),
          findsOneWidget,
        );
        await key.currentState!.submit();
        await tester.pumpAndSettle();
        expect(products.creates, 1);
        expect(stock.calls, createFails ? 0 : 1);
        expect(saved, 0);
      },
    );
  }
}
