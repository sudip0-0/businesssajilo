import 'package:businesssajilo/core/l10n/app_localizations.dart';
import 'package:businesssajilo/core/theme/app_theme.dart';
import 'package:businesssajilo/data/repositories/bills_repository.dart';
import 'package:businesssajilo/data/repositories/customers_repository.dart';
import 'package:businesssajilo/data/repositories/products_repository.dart';
import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/domain/models/bill.dart';
import 'package:businesssajilo/domain/models/business.dart';
import 'package:businesssajilo/domain/models/customer.dart';
import 'package:businesssajilo/domain/models/member.dart';
import 'package:businesssajilo/domain/models/product.dart';
import 'package:businesssajilo/domain/models/session_state.dart';
import 'package:businesssajilo/features/auth/providers/auth_provider.dart';
import 'package:businesssajilo/features/onboarding/first_bill_checklist_card.dart';
import 'package:businesssajilo/features/onboarding/first_bill_checklist_provider.dart';
import 'package:businesssajilo/web/features/dashboard/sections/web_first_bill_checklist_card.dart';
import 'package:businesssajilo/web/theme/web_theme.dart';
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

class _ProductsStub implements ProductsRepository {
  _ProductsStub(this.items);
  final List<Product> items;

  @override
  Future<List<Product>> list({
    bool activeOnly = true,
    int offset = 0,
    int? limit,
    String? query,
    ProductStockFilter stockFilter = ProductStockFilter.all,
  }) async => items;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CustomersStub implements CustomersRepository {
  _CustomersStub(this.items);
  final List<Customer> items;

  @override
  Future<List<Customer>> list({
    int offset = 0,
    int? limit,
    String? query,
    bool includeBalances = true,
    CustomerBalanceFilter balanceFilter = CustomerBalanceFilter.all,
  }) async => items;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _BillsStub implements BillsRepository {
  _BillsStub(this.items);
  final List<Bill> items;

  @override
  Future<List<Bill>> list({
    int offset = 0,
    int? limit,
    BillStatus? status,
  }) async => items;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('isBusinessProfileReady checks business name and phone/address', () {
    expect(isBusinessProfileReady(null), isFalse);
    expect(
      isBusinessProfileReady(const Business(id: 'b1', name: 'Sajilo Traders')),
      isFalse,
    );
    expect(
      isBusinessProfileReady(
        const Business(id: 'b1', name: 'Sajilo Traders', phone: '9841000000'),
      ),
      isTrue,
    );
    expect(
      isBusinessProfileReady(
        const Business(id: 'b1', name: 'Sajilo Traders', address: 'Kathmandu'),
      ),
      isTrue,
    );
  });

  test('firstBillChecklistProvider returns null for non-owner roles', () async {
    for (final role in [Role.sales, Role.warehouse, Role.customer]) {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(
            () => _TestAuth(
              Member(
                id: 'm1',
                businessId: 'biz-a',
                authUserId: 'u1',
                role: role,
                displayName: role.name,
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final state = await container.read(firstBillChecklistProvider.future);
      expect(state, isNull, reason: 'Checklist must be owner-only ($role)');
    }
  });

  test(
    'auto-hides when all 4 steps are complete and scopes dismissal per tenant',
    () async {
      const biz = Business(
        id: 'biz-a',
        name: 'Everest Distributors',
        phone: '9841000001',
      );
      final completeContainer = ProviderContainer(
        overrides: [
          authProvider.overrideWith(
            () => _TestAuth(
              const Member(
                id: 'o1',
                businessId: 'biz-a',
                authUserId: 'u1',
                role: Role.owner,
                displayName: 'Owner',
              ),
            ),
          ),
          currentBusinessProvider.overrideWith((ref) async => biz),
          productsRepositoryProvider.overrideWithValue(
            _ProductsStub(const [
              Product(id: 'p1', businessId: 'biz-a', name: 'Rice', unit: 'bag'),
            ]),
          ),
          customersRepositoryProvider.overrideWithValue(
            _CustomersStub(const [
              Customer(
                id: 'c1',
                businessId: 'biz-a',
                memberId: 'cm1',
                shopName: 'Shop',
              ),
            ]),
          ),
          billsRepositoryProvider.overrideWithValue(
            _BillsStub(const [
              Bill(
                id: 'bill-1',
                businessId: 'biz-a',
                billNo: 'BS-0001',
                createdBy: 'o1',
                status: BillStatus.paid,
                itemsTotal: 1000,
                discount: 0,
                grandTotal: 1000,
              ),
            ]),
          ),
        ],
      );
      addTearDown(completeContainer.dispose);
      final complete = await completeContainer.read(
        firstBillChecklistProvider.future,
      );
      expect(complete?.isAllComplete, isTrue);
      expect(complete?.shouldShow, isFalse);

      const store = FirstBillChecklistStore();
      await store.dismiss('biz-a');
      expect(await store.isDismissed('biz-a'), isTrue);
      expect(await store.isDismissed('biz-b'), isFalse);
    },
  );

  for (final isWeb in [false, true]) {
    for (final locale in [const Locale('en'), const Locale('ne')]) {
      testWidgets(
        '${isWeb ? 'Web' : 'Mobile'} checklist renders and dismisses cleanly (${locale.languageCode})',
        (tester) async {
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                authProvider.overrideWith(
                  () => _TestAuth(
                    const Member(
                      id: 'o1',
                      businessId: 'biz-new',
                      authUserId: 'u1',
                      role: Role.owner,
                      displayName: 'Owner',
                    ),
                  ),
                ),
                currentBusinessProvider.overrideWith(
                  (ref) async => const Business(
                    id: 'biz-new',
                    name: 'New Shop',
                    phone: '9841000001',
                  ),
                ),
                productsRepositoryProvider.overrideWithValue(
                  _ProductsStub(const []),
                ),
                customersRepositoryProvider.overrideWithValue(
                  _CustomersStub(const []),
                ),
                billsRepositoryProvider.overrideWithValue(_BillsStub(const [])),
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
                  body: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: isWeb
                        ? const WebFirstBillChecklistCard()
                        : const FirstBillChecklistCard(),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final l10n = AppLocalizations.of(
            tester.element(find.byType(Scaffold)),
          );
          expect(find.text(l10n.firstBillChecklistTitle), findsOneWidget);
          expect(
            find.text(l10n.firstBillChecklistProgress(1, 4)),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);

          await tester.tap(find.byTooltip(l10n.firstBillChecklistDismiss));
          await tester.pumpAndSettle();

          expect(find.text(l10n.firstBillChecklistTitle), findsNothing);
          expect(
            await const FirstBillChecklistStore().isDismissed('biz-new'),
            isTrue,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
