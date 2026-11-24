import 'package:businesssajilo/core/l10n/app_localizations.dart';
import 'package:businesssajilo/core/theme/app_theme.dart';
import 'package:businesssajilo/data/repositories/orders_repository.dart';
import 'package:businesssajilo/data/repositories/product_import_repository.dart';
import 'package:businesssajilo/data/repositories/products_repository.dart';
import 'package:businesssajilo/data/repositories/stock_repository.dart';
import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/domain/models/catalog_product.dart';
import 'package:businesssajilo/domain/models/customer.dart';
import 'package:businesssajilo/domain/models/member.dart';
import 'package:businesssajilo/domain/models/order.dart';
import 'package:businesssajilo/domain/models/product.dart';
import 'package:businesssajilo/domain/models/session_state.dart';
import 'package:businesssajilo/features/auth/providers/auth_provider.dart';
import 'package:businesssajilo/features/customers/providers.dart';
import 'package:businesssajilo/features/inventory/product_excel_import.dart';
import 'package:businesssajilo/features/inventory/product_import_session_store.dart';
import 'package:businesssajilo/features/inventory/product_import_sheet.dart';
import 'package:businesssajilo/features/orders/cart_draft_store.dart';
import 'package:businesssajilo/features/orders/cart_provider.dart';
import 'package:businesssajilo/features/orders/cart_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemberAuth extends AuthController {
  _MemberAuth(this._member);
  final Member? _member;

  @override
  AsyncValue<SessionState> build() =>
      AsyncValue.data(SessionState(member: _member));
}

class _FakeOrdersRepo implements OrdersRepository {
  bool failNext = false;
  final placementIds = <String?>[];
  final notes = <String?>[];

  @override
  Future<Order> placeOrder({
    String? id,
    required String customerId,
    required List<OrderLineInput> lines,
    String? note,
  }) async {
    placementIds.add(id);
    notes.add(note);
    if (failNext) {
      failNext = false;
      throw StateError('network timeout');
    }
    return Order(
      id: id ?? 'order-1',
      businessId: 'biz-a',
      customerId: customerId,
      status: OrderStatus.placed,
      customerNote: note,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeIdempotentImportRepo implements ProductImportRepository {
  final seenOpIds = <String, Product>{};
  final callLog =
      <({String opId, String name, String? sku, int openingStock})>[];
  String? failOnceForName;

  @override
  Future<ProductImportRpcResult> createProductWithStock({
    required String opId,
    required String name,
    String? nameNp,
    String? sku,
    String unit = 'piece',
    int costPrice = 0,
    int referencePrice = 0,
    int lowStockThreshold = 0,
    int openingStock = 0,
    String openingStockReason = 'Opening stock',
  }) async {
    callLog.add((opId: opId, name: name, sku: sku, openingStock: openingStock));
    if (failOnceForName == name) {
      failOnceForName = null;
      throw StateError('transient failure');
    }
    final existing = seenOpIds[opId];
    if (existing != null) {
      return ProductImportRpcResult(product: existing, created: false);
    }
    final created = Product(
      id: 'prod-$opId',
      businessId: 'biz-a',
      name: name,
      sku: sku,
      unit: unit,
      stockCached: openingStock,
    );
    seenOpIds[opId] = created;
    return ProductImportRpcResult(
      product: created,
      movementId: openingStock > 0 ? 'mov-$opId' : null,
      created: true,
    );
  }
}

class _NoopProductsRepo implements ProductsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoopStockRepo implements StockRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Durable Cart Draft', () {
    const customerA = Member(
      id: 'cust-m1',
      businessId: 'biz-a',
      authUserId: 'u-c1',
      role: Role.customer,
      displayName: 'Retailer A',
    );
    const customerB = Member(
      id: 'cust-m2',
      businessId: 'biz-b',
      authUserId: 'u-c2',
      role: Role.customer,
      displayName: 'Retailer B',
    );

    test(
      'persists items, note, and placement UUID across restart and isolates tenants',
      () async {
        final firstContainer = ProviderContainer(
          overrides: [authProvider.overrideWith(() => _MemberAuth(customerA))],
        );
        addTearDown(firstContainer.dispose);

        final firstNotifier = firstContainer.read(cartProvider.notifier);
        await firstNotifier.hydrationComplete;
        firstNotifier.setQty('prod-1', 3);
        firstNotifier.setNote('Deliver before 4 PM');
        final savedPlacementId = firstNotifier.placementId;

        // Wait for fire-and-forget SharedPreferences write.
        await Future<void>.delayed(const Duration(milliseconds: 20));

        // Simulate app restart with a brand new ProviderContainer.
        final restarted = ProviderContainer(
          overrides: [authProvider.overrideWith(() => _MemberAuth(customerA))],
        );
        addTearDown(restarted.dispose);
        final restartedNotifier = restarted.read(cartProvider.notifier);
        await restartedNotifier.hydrationComplete;

        expect(restarted.read(cartProvider), {'prod-1': 3});
        expect(restartedNotifier.note, 'Deliver before 4 PM');
        expect(restartedNotifier.placementId, savedPlacementId);
        expect(restartedNotifier.restoredFromDraft, isTrue);

        // Different tenant/member must NOT see customerA's draft.
        final otherTenant = ProviderContainer(
          overrides: [authProvider.overrideWith(() => _MemberAuth(customerB))],
        );
        addTearDown(otherTenant.dispose);
        await otherTenant.read(cartProvider.notifier).hydrationComplete;
        expect(otherTenant.read(cartProvider), isEmpty);
        expect(otherTenant.read(cartProvider.notifier).note, isEmpty);
        expect(
          otherTenant.read(cartProvider.notifier).placementId,
          isNot(savedPlacementId),
        );
      },
    );

    testWidgets(
      'CartSheet restores note/placementId and clears persisted draft on confirmed placement',
      (tester) async {
        const scope = CartDraftScope(businessId: 'biz-a', memberId: 'cust-m1');
        await const CartDraftStore().save(
          scope,
          const CartDraft(
            placementId: 'stable-order-uuid-123',
            quantities: {'prod-1': 2},
            note: 'Urgent order',
          ),
        );

        final ordersRepo = _FakeOrdersRepo()..failNext = true;
        final container = ProviderContainer(
          overrides: [
            authProvider.overrideWith(() => _MemberAuth(customerA)),
            ordersRepositoryProvider.overrideWithValue(ordersRepo),
            ownCustomerProvider.overrideWith(
              (ref) async => const Customer(
                id: 'c-1',
                businessId: 'biz-a',
                memberId: 'cust-m1',
                shopName: 'Retailer A',
              ),
            ),
          ],
        );
        addTearDown(container.dispose);
        await container.read(cartProvider.notifier).hydrationComplete;

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.light(),
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(
                body: CartSheet(
                  products: [
                    CatalogProduct(
                      id: 'prod-1',
                      businessId: 'biz-a',
                      name: 'Rice',
                      unit: 'bag',
                    ),
                  ],
                  quantities: {'prod-1': 2},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Urgent order'), findsOneWidget);

        // First attempt fails -> draft & placementId stay persisted.
        await tester.tap(find.widgetWithText(FilledButton, 'Place Order'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.widgetWithText(FilledButton, 'Place Order'),
          ),
        );
        await tester.pumpAndSettle();

        expect(ordersRepo.placementIds, ['stable-order-uuid-123']);
        expect(await const CartDraftStore().load(scope), isNotNull);

        // Second attempt succeeds with SAME placementId and clears durable draft.
        await tester.tap(find.widgetWithText(FilledButton, 'Place Order'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.widgetWithText(FilledButton, 'Place Order'),
          ),
        );
        await tester.pumpAndSettle();

        expect(ordersRepo.placementIds, [
          'stable-order-uuid-123',
          'stable-order-uuid-123',
        ]);
        expect(ordersRepo.notes.last, 'Urgent order');
        final remainingDraft = await tester.runAsync(
          () => const CartDraftStore().load(scope),
        );
        expect(remainingDraft, isNull);
        expect(
          container.read(cartProvider.notifier).placementId,
          isNot('stable-order-uuid-123'),
        );
      },
    );
  });

  group('Durable Idempotent Import Recovery', () {
    const ownerMember = Member(
      id: 'owner-1',
      businessId: 'biz-a',
      authUserId: 'u-o1',
      role: Role.owner,
      displayName: 'Owner',
    );
    const salesScope = ImportSessionScope(
      businessId: 'biz-a',
      memberId: 'sales-1',
      role: Role.sales,
    );
    const ownerScope = ImportSessionScope(
      businessId: 'biz-a',
      memberId: 'owner-1',
      role: Role.owner,
    );

    test(
      'resumes failed rows with identical operationId & SKU without duplicating completed rows',
      () async {
        final rpc = _FakeIdempotentImportRepo()..failOnceForName = 'Dal';
        final runner = ProductImportRunner(
          products: _NoopProductsRepo(),
          stock: _NoopStockRepo(),
          memberId: ownerMember.id,
          idempotentImport: rpc,
          role: Role.owner,
        );
        final session = ProductImportSession.create(
          filename: 'catalog.xlsx',
          rows: const [
            ProductImportRow(
              rowNumber: 2,
              name: 'Rice',
              sku: 'RICE-1',
              initialQuantity: 5,
            ),
            ProductImportRow(rowNumber: 3, name: 'Dal', initialQuantity: 10),
          ],
        );

        const store = ProductImportSessionStore();
        final afterFirst = await runner.runSession(
          session,
          onSessionUpdated: (s) => store.save(ownerScope, s),
        );
        expect(afterFirst.completedCount, 1);
        expect(afterFirst.remainingCount, 1);

        // Tenant/role isolation: another role cannot see owner's saved session.
        expect(await store.load(salesScope), isNull);

        // Reload persisted session (simulating close/reopen) and resume safely.
        final reloaded = await store.load(ownerScope);
        expect(reloaded, isNotNull);
        expect(reloaded!.rows[1].operationId, session.rows[1].operationId);
        expect(reloaded.rows[1].sku, session.rows[1].sku);

        final afterResume = await runner.runSession(
          reloaded,
          onSessionUpdated: (s) => store.save(ownerScope, s),
        );
        expect(afterResume.isFullySucceeded, isTrue);
        expect(await store.load(ownerScope), isNull);

        // Rice was called once; Dal was called twice with identical opId & SKU.
        expect(rpc.callLog.where((c) => c.name == 'Rice'), hasLength(1));
        final dalCalls = rpc.callLog.where((c) => c.name == 'Dal').toList();
        expect(dalCalls, hasLength(2));
        expect(dalCalls[0].opId, dalCalls[1].opId);
        expect(dalCalls[0].sku, dalCalls[1].sku);
      },
    );

    test(
      'blocks sales role from recording opening stock during import',
      () async {
        final rpc = _FakeIdempotentImportRepo();
        final runner = ProductImportRunner(
          products: _NoopProductsRepo(),
          stock: _NoopStockRepo(),
          memberId: 'sales-1',
          idempotentImport: rpc,
          role: Role.sales,
        );
        final session = ProductImportSession.create(
          filename: 'sales.csv',
          rows: const [
            ProductImportRow(rowNumber: 2, name: 'Tea', initialQuantity: 0),
            ProductImportRow(rowNumber: 3, name: 'Sugar', initialQuantity: 15),
          ],
        );
        final finished = await runner.runSession(session);
        expect(finished.completedCount, 1);
        expect(finished.remainingCount, 1);
        expect(finished.allErrors.single.code, 'opening_stock_owner_only');
        expect(rpc.callLog.map((c) => c.name), ['Tea']);
      },
    );

    testWidgets(
      'ProductImportSheet shows saved session banner and resumes safely',
      (tester) async {
        final rpc = _FakeIdempotentImportRepo();
        final savedSession = ProductImportSession(
          sessionId: 'sess-1',
          filename: 'items.csv',
          createdAt: DateTime.utc(2026, 11, 24),
          rows: const [
            ProductImportSessionRow(
              operationId: 'op-done',
              sku: 'SKU-1',
              status: ProductImportRowStatus.completed,
              productId: 'p-1',
              row: ProductImportRow(rowNumber: 2, name: 'Rice'),
            ),
            ProductImportSessionRow(
              operationId: 'op-retry',
              sku: 'SKU-2',
              status: ProductImportRowStatus.failed,
              errorCode: 'create_unconfirmed',
              row: ProductImportRow(
                rowNumber: 3,
                name: 'Dal',
                initialQuantity: 5,
              ),
            ),
          ],
        );
        await const ProductImportSessionStore().save(ownerScope, savedSession);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith(() => _MemberAuth(ownerMember)),
              productsRepositoryProvider.overrideWithValue(_NoopProductsRepo()),
              stockRepositoryProvider.overrideWithValue(_NoopStockRepo()),
              productImportRepositoryProvider.overrideWithValue(rpc),
            ],
            child: MaterialApp(
              theme: AppTheme.light(),
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(body: ProductImportSheet()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)));
        expect(find.text(l10n.importSessionSavedTitle), findsOneWidget);
        expect(find.text(l10n.importResumeSafe), findsOneWidget);

        await tester.tap(find.text(l10n.importResumeSafe));
        await tester.pumpAndSettle();

        expect(rpc.callLog, hasLength(1));
        expect(rpc.callLog.single.opId, 'op-retry');
        expect(rpc.callLog.single.sku, 'SKU-2');
        expect(
          await const ProductImportSessionStore().load(ownerScope),
          isNull,
        );
        expect(tester.takeException(), isNull);
      },
    );
  });
}
