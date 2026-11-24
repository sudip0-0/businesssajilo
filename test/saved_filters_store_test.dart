import 'package:businesssajilo/core/l10n/app_localizations.dart';
import 'package:businesssajilo/core/preferences/saved_filters_store.dart';
import 'package:businesssajilo/core/theme/app_theme.dart';
import 'package:businesssajilo/core/ui/reset_filters_button.dart';
import 'package:businesssajilo/data/repositories/products_repository.dart';
import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/domain/models/member.dart';
import 'package:businesssajilo/domain/models/product.dart';
import 'package:businesssajilo/domain/models/session_state.dart';
import 'package:businesssajilo/features/auth/providers/auth_provider.dart';
import 'package:businesssajilo/features/billing/bill_period_codec.dart';
import 'package:businesssajilo/features/inventory/product_list_screen.dart';
import 'package:businesssajilo/features/reports/report_period.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestAuth extends AuthController {
  _TestAuth(this._member);
  final Member _member;

  @override
  AsyncValue<SessionState> build() =>
      AsyncValue.data(SessionState(member: _member));
}

class _FakeProductsRepo implements ProductsRepository {
  final calls = <ProductStockFilter>[];

  @override
  Future<List<Product>> list({
    bool activeOnly = true,
    int offset = 0,
    int? limit,
    String? query,
    ProductStockFilter stockFilter = ProductStockFilter.all,
  }) async {
    calls.add(stockFilter);
    return const [
      Product(
        id: 'p1',
        businessId: 'biz-a',
        name: 'Mustard Oil',
        unit: 'bottle',
        lowStockThreshold: 10,
        stockCached: 3,
      ),
    ];
  }

  @override
  Future<int> lowStockCount() async => 1;

  @override
  Future<String?> signedImageUrl(String? storagePath) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SavedFiltersStore tenant, member, and role isolation', () {
    const store = SavedFiltersStore();
    const ownerBizA = FilterScope(
      businessId: 'biz-a',
      memberId: 'm-1',
      role: Role.owner,
    );
    const ownerBizB = FilterScope(
      businessId: 'biz-b',
      memberId: 'm-1',
      role: Role.owner,
    );
    const salesBizA = FilterScope(
      businessId: 'biz-a',
      memberId: 'm-1',
      role: Role.sales,
    );
    const warehouseBizA = FilterScope(
      businessId: 'biz-a',
      memberId: 'm-2',
      role: Role.warehouse,
    );

    test('isolates inventory filters by business, member, and role', () async {
      const saved = InventoryListFilterState(
        stockFilter: ProductStockFilter.low,
        showInactive: true,
        sortField: InventorySortField.quantity,
        sortAscending: false,
      );
      await store.saveInventory(ownerBizA, saved);

      expect(await store.loadInventory(ownerBizA, canEdit: true), saved);
      expect(
        await store.loadInventory(ownerBizB, canEdit: true),
        InventoryListFilterState.defaults,
      );
      expect(
        await store.loadInventory(salesBizA, canEdit: true),
        InventoryListFilterState.defaults,
      );
      expect(
        await store.loadInventory(warehouseBizA, canEdit: false),
        InventoryListFilterState.defaults,
      );
    });

    test('sanitizes showInactive when role cannot edit products', () async {
      await store.saveInventory(
        warehouseBizA,
        const InventoryListFilterState(
          stockFilter: ProductStockFilter.out,
          showInactive: true,
        ),
      );
      final loaded = await store.loadInventory(warehouseBizA, canEdit: false);
      expect(loaded.stockFilter, ProductStockFilter.out);
      expect(loaded.showInactive, isFalse);
    });

    test('denies customer balance filter persistence for warehouse', () async {
      await store.saveCustomers(
        warehouseBizA,
        const CustomerListFilterState(balanceFilter: CustomerBalanceFilter.due),
      );
      expect(
        await store.loadCustomers(warehouseBizA),
        CustomerListFilterState.defaults,
      );

      await store.saveCustomers(
        ownerBizA,
        const CustomerListFilterState(
          balanceFilter: CustomerBalanceFilter.due,
          sortField: CustomerListSortField.balance,
          sortAscending: false,
        ),
      );
      final ownerLoaded = await store.loadCustomers(ownerBizA);
      expect(ownerLoaded.balanceFilter, CustomerBalanceFilter.due);
      expect(ownerLoaded.sortField, CustomerListSortField.balance);
      expect(ownerLoaded.sortAscending, isFalse);
    });

    test('round-trips bill preset and custom date periods', () async {
      final preset = ReportPeriod.preset(ReportPeriodPreset.bsThisMonth);
      final encodedPreset = encodeBillPeriod(preset);
      final presetState = BillListFilterState(
        status: BillListStatusFilter.due,
        periodQuery: encodedPreset.periodQuery,
        customFromMs: encodedPreset.customFromMs,
        customToMs: encodedPreset.customToMs,
        sortField: BillListSortField.amount,
        sortAscending: true,
      );
      await store.saveBills(ownerBizA, presetState);
      final restoredPreset = await store.loadBills(ownerBizA);
      expect(restoredPreset, presetState);
      expect(
        decodeBillPeriod(restoredPreset)?.preset,
        ReportPeriodPreset.bsThisMonth,
      );

      final custom = ReportPeriod.custom(
        fromDate: DateTime.utc(2026, 3, 1),
        toDate: DateTime.utc(2026, 3, 15),
      );
      final encodedCustom = encodeBillPeriod(custom);
      final customState = BillListFilterState(
        periodQuery: encodedCustom.periodQuery,
        customFromMs: encodedCustom.customFromMs,
        customToMs: encodedCustom.customToMs,
      );
      await store.saveBills(ownerBizA, customState);
      final restoredCustom = await store.loadBills(ownerBizA);
      final decodedCustom = decodeBillPeriod(restoredCustom);
      expect(decodedCustom, custom);
    });

    test('saves and clears orders filter when reset to defaults', () async {
      await store.saveOrders(
        salesBizA,
        const OrderListFilterState(staffFilterName: 'billed'),
      );
      expect((await store.loadOrders(salesBizA)).staffFilterName, 'billed');

      await store.saveOrders(salesBizA, OrderListFilterState.defaults);
      expect(
        (await store.loadOrders(salesBizA)).staffFilterName,
        'needsAction',
      );
    });
  });

  testWidgets('ProductListScreen restores saved filters and resets cleanly', (
    tester,
  ) async {
    const scope = FilterScope(
      businessId: 'biz-a',
      memberId: 'owner-1',
      role: Role.owner,
    );
    await const SavedFiltersStore().saveInventory(
      scope,
      const InventoryListFilterState(stockFilter: ProductStockFilter.low),
    );

    final repo = _FakeProductsRepo();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(
            () => _TestAuth(
              const Member(
                id: 'owner-1',
                businessId: 'biz-a',
                authUserId: 'u1',
                role: Role.owner,
                displayName: 'Owner',
              ),
            ),
          ),
          productsRepositoryProvider.overrideWithValue(repo),
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
          home: const Scaffold(
            body: ProductListScreen(canEdit: true, canManageStock: true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(repo.calls, contains(ProductStockFilter.low));
    expect(find.byType(ResetFiltersButton), findsOneWidget);

    await tester.tap(find.byType(ResetFiltersButton));
    await tester.pumpAndSettle();

    expect(find.byType(ResetFiltersButton), findsNothing);
    expect(repo.calls.last, ProductStockFilter.all);
    expect(
      await const SavedFiltersStore().loadInventory(scope, canEdit: true),
      InventoryListFilterState.defaults,
    );
    expect(tester.takeException(), isNull);
  });
}
