import 'package:businesssajilo/core/l10n/app_localizations.dart';
import 'package:businesssajilo/core/theme/app_theme.dart';
import 'package:businesssajilo/core/utils/money.dart';
import 'package:businesssajilo/data/repositories/products_repository.dart';
import 'package:businesssajilo/data/repositories/stock_reconciliation_repository.dart';
import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/domain/models/member.dart';
import 'package:businesssajilo/domain/models/product.dart';
import 'package:businesssajilo/domain/models/session_state.dart';
import 'package:businesssajilo/features/auth/providers/auth_provider.dart';
import 'package:businesssajilo/features/inventory/stock_count_controller.dart';
import 'package:businesssajilo/features/inventory/stock_count_screen.dart';
import 'package:businesssajilo/web/features/inventory/web_stock_count_dialog.dart';
import 'package:businesssajilo/web/theme/web_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _productsFixture = [
  Product(
    id: 'prod-1',
    businessId: 'biz-1',
    name: 'Basmati Rice',
    sku: 'RICE-25',
    unit: 'bag',
    costPrice: 215000,
    referencePrice: 245000,
    stockCached: 10,
  ),
  Product(
    id: 'prod-2',
    businessId: 'biz-1',
    name: 'Lentil Dal',
    sku: 'DAL-10',
    unit: 'kg',
    costPrice: 18500,
    referencePrice: 22500,
    stockCached: 20,
  ),
];

class _RoleAuth extends AuthController {
  _RoleAuth(this._role);
  final Role _role;

  @override
  AsyncValue<SessionState> build() => AsyncValue.data(
    SessionState(
      member: Member(
        id: '${_role.name}-member',
        businessId: 'biz-1',
        authUserId: 'u-${_role.name}',
        role: _role,
        displayName: _role.name,
      ),
    ),
  );
}

class _FakeProductsRepo implements ProductsRepository {
  @override
  Future<List<Product>> list({
    bool activeOnly = true,
    int offset = 0,
    int? limit,
    String? query,
    ProductStockFilter stockFilter = ProductStockFilter.all,
  }) async => _productsFixture;

  @override
  Future<int> lowStockCount() async => 0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingReconcileRepo implements StockReconciliationRepository {
  final calls =
      <
        ({
          String opId,
          String reason,
          List<StockCountLineInput> items,
          String createdByMemberId,
        })
      >[];

  @override
  Future<StockCountReconcileResult> reconcileStockCount({
    required String opId,
    required String reason,
    required List<StockCountLineInput> items,
    required String createdByMemberId,
  }) async {
    calls.add((
      opId: opId,
      reason: reason,
      items: items,
      createdByMemberId: createdByMemberId,
    ));
    return StockCountReconcileResult(
      opId: opId,
      created: true,
      reason: reason,
      totalItems: items.length,
      adjustedCount: items.length,
      unchangedCount: 0,
      items: [
        for (final i in items)
          StockCountLineResult(
            productId: i.productId,
            name: '',
            previousStock: i.systemStock ?? 0,
            countedQty: i.countedQty,
            delta: i.countedQty - (i.systemStock ?? 0),
            newStock: i.countedQty,
            movementId: 'mov-${i.productId}',
          ),
      ],
    );
  }
}

void main() {
  group('StockCountDraft pure logic', () {
    test('parses ASCII & Devanagari digits and rejects invalid numbers', () {
      expect(parseNonNegativeStockCount('0'), 0);
      expect(parseNonNegativeStockCount('42'), 42);
      expect(parseNonNegativeStockCount('१२५'), 125);
      expect(parseNonNegativeStockCount('-1'), isNull);
      expect(parseNonNegativeStockCount('12.5'), isNull);
      expect(parseNonNegativeStockCount('abc'), isNull);
      expect(parseNonNegativeStockCount(''), isNull);
    });

    test('computes variance and rotates opId only on edits after submit', () {
      final draft = StockCountDraft(opId: 'op-initial');
      draft.setRawInput('prod-1', '14'); // +4
      draft.setRawInput('prod-2', '17'); // -3

      expect(draft.changedEntries(_productsFixture), hasLength(2));
      expect(draft.netVariance(_productsFixture), 1);
      expect(draft.opId, 'op-initial');

      draft.markAttemptStarted();
      expect(draft.opId, 'op-initial'); // Same opId on retry

      draft.setRawInput('prod-1', '15'); // User edits after attempt
      expect(draft.opId, isNot('op-initial'));
    });
  });

  testWidgets('blocks sales and customer roles from stock count', (
    tester,
  ) async {
    for (final role in [Role.sales, Role.customer]) {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(() => _RoleAuth(role)),
            productsRepositoryProvider.overrideWithValue(_FakeProductsRepo()),
            stockReconciliationRepositoryProvider.overrideWithValue(
              _RecordingReconcileRepo(),
            ),
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
            home: const StockCountScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)));
      expect(find.text(l10n.errorPermission), findsOneWidget);
      expect(find.text('Basmati Rice'), findsNothing);
    }
  });

  for (final isWeb in [false, true]) {
    for (final locale in [const Locale('en'), const Locale('ne')]) {
      testWidgets(
        'warehouse reconciles stock on ${isWeb ? 'Web' : 'Mobile'} with zero price/finance leakage (${locale.languageCode})',
        (tester) async {
          tester.view.physicalSize = isWeb
              ? const Size(1024, 768)
              : const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final reconcileRepo = _RecordingReconcileRepo();
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                authProvider.overrideWith(() => _RoleAuth(Role.warehouse)),
                productsRepositoryProvider.overrideWithValue(
                  _FakeProductsRepo(),
                ),
                stockReconciliationRepositoryProvider.overrideWithValue(
                  reconcileRepo,
                ),
              ],
              child: MaterialApp(
                locale: locale,
                theme: isWeb ? WebTheme.light() : AppTheme.light(),
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: AppLocalizations.supportedLocales,
                home: Scaffold(
                  body: isWeb
                      ? const WebStockCountDialog()
                      : const StockCountScreen(),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Warehouse privacy: zero cost price, reference price, or ledger terms.
          for (final p in _productsFixture) {
            for (final paisa in [p.costPrice, p.referencePrice]) {
              expect(
                find.textContaining(
                  formatNpr(Paisa(paisa), showSymbol: false, showPaisa: false),
                ),
                findsNothing,
              );
            }
          }
          final l10n = AppLocalizations.of(
            tester.element(find.byType(Scaffold).first),
          );
          expect(find.text(l10n.costPrice), findsNothing);
          expect(find.text(l10n.referencePrice), findsNothing);
          expect(find.text(l10n.balance), findsNothing);

          // TextFields: index 0 = search, index 1 = prod-1 qty, index 2 = prod-2 qty, index 3 = reason.
          final fields = find.byType(TextField);
          await tester.enterText(fields.at(1), '14'); // 10 -> 14 (+4)
          await tester.enterText(fields.at(2), '20'); // 20 -> 20 (0, unchanged)
          await tester.pumpAndSettle();

          expect(find.text('+4'), findsOneWidget);

          // Submit disabled until reason is entered.
          final submitFinder = find.widgetWithText(
            FilledButton,
            '${l10n.stockCountSubmit} (1)',
          );
          expect(submitFinder, findsOneWidget);
          expect(tester.widget<FilledButton>(submitFinder).onPressed, isNull);

          await tester.enterText(fields.at(3), 'Monthly godown audit');
          await tester.pumpAndSettle();

          expect(
            tester.widget<FilledButton>(submitFinder).onPressed,
            isNotNull,
          );
          await tester.tap(submitFinder);
          await tester.pumpAndSettle();

          expect(reconcileRepo.calls, hasLength(1));
          final call = reconcileRepo.calls.single;
          expect(call.opId, isNotEmpty);
          expect(call.reason, 'Monthly godown audit');
          expect(call.createdByMemberId, 'warehouse-member');
          expect(call.items, hasLength(1));
          expect(call.items.single.productId, 'prod-1');
          expect(call.items.single.countedQty, 14);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
