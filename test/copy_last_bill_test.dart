import 'package:businesssajilo/core/l10n/app_localizations.dart';
import 'package:businesssajilo/data/repositories/customers_repository.dart';
import 'package:businesssajilo/data/repositories/orders_repository.dart';
import 'package:businesssajilo/data/repositories/products_repository.dart';
import 'package:businesssajilo/data/repositories/quotes_repository.dart';
import 'package:businesssajilo/domain/models/order.dart';
import 'package:businesssajilo/domain/models/order_item.dart';
import 'package:businesssajilo/domain/models/product.dart';
import 'package:businesssajilo/domain/models/quote.dart';
import 'package:businesssajilo/domain/models/customer.dart';
import 'package:businesssajilo/domain/models/member.dart';
import 'package:businesssajilo/domain/models/session_state.dart';
import 'package:businesssajilo/features/auth/providers/auth_provider.dart';
import 'package:businesssajilo/features/inventory/providers.dart';
import 'package:businesssajilo/web/features/billing/web_bill_form_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:businesssajilo/data/repositories/bills_repository.dart';
import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/domain/models/bill.dart';
import 'package:businesssajilo/domain/models/bill_item.dart';
import 'package:businesssajilo/features/billing/copy_last_bill.dart';
import 'package:businesssajilo/features/billing/bill_form_screen.dart';
import 'package:flutter_test/flutter_test.dart';

class _ListGetBills implements BillsRepository {
  _ListGetBills({required this.listed, this.detailed});

  final List<Bill> listed;
  final Bill? detailed;
  var getCalls = 0;

  @override
  Future<List<Bill>> list({
    int offset = 0,
    int? limit,
    BillStatus? status,
  }) async => listed;

  @override
  Future<Bill> get(String id) async {
    getCalls++;
    return detailed ?? (throw StateError('missing $id'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Bill _bill({required String id, List<BillItem> items = const []}) {
  return Bill(
    id: id,
    businessId: 'biz',
    billNo: 'BS-0001',
    createdBy: 'm1',
    status: BillStatus.due,
    items: items,
  );
}

class _BillingOrders implements OrdersRepository {
  @override
  Future<BillingOrderDraft?> billingDraftFromOrder(String orderId) async =>
      null;

  @override
  Future<Order> get(String id) async => Order(
    id: id,
    businessId: 'biz',
    customerId: 'customer',
    status: OrderStatus.received,
    items: const [
      OrderItem(
        id: 'order-item',
        orderId: 'order',
        productId: 'product',
        productName: 'Rice',
        qty: 1,
      ),
    ],
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _BillingProducts implements ProductsRepository {
  @override
  Future<Product> get(String id) async =>
      Product(id: id, businessId: 'biz', name: 'Rice', referencePrice: 125050);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _BillingQuotes extends QuotesRepository {
  _BillingQuotes() : super(null);

  @override
  Future<Quote?> latestAccepted(String orderId) async => null;
}

class _RoleAuth extends AuthController {
  _RoleAuth(this.role);
  final Role role;

  @override
  AsyncValue<SessionState> build() => AsyncValue.data(
    SessionState(
      member: Member(
        id: 'member',
        businessId: 'biz',
        authUserId: 'auth',
        role: role,
        displayName: 'Staff',
      ),
    ),
  );
}

class _BillingCustomers implements CustomersRepository {
  final listBalances = <bool>[];
  final getBalances = <bool>[];
  static const customer = Customer(
    id: 'customer',
    businessId: 'biz',
    memberId: 'customer-member',
    shopName: 'Directory Shop',
  );

  @override
  Future<List<Customer>> list({
    int offset = 0,
    int? limit,
    String? query,
    bool includeBalances = true,
    CustomerBalanceFilter balanceFilter = CustomerBalanceFilter.all,
  }) async {
    listBalances.add(includeBalances);
    return [customer];
  }

  @override
  Future<Customer> get(String id, {bool includeBalances = true}) async {
    getBalances.add(includeBalances);
    return customer;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final role in [Role.warehouse, Role.owner, Role.sales]) {
    testWidgets(
      'mobile copy bill uses role-appropriate customer identity for $role',
      (tester) async {
        final customers = _BillingCustomers();
        final bill = _bill(id: 'bill').copyWith(customerId: 'customer');
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith(() => _RoleAuth(role)),
              customersRepositoryProvider.overrideWithValue(customers),
              billsRepositoryProvider.overrideWithValue(
                _ListGetBills(listed: [bill], detailed: bill),
              ),
            ],
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: BillFormScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Copy last bill'));
        await tester.pumpAndSettle();

        expect(customers.getBalances, [role.canViewCustomerBalance]);
        expect(find.text('Directory Shop'), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );

    for (final fromOrder in [false, true]) {
      testWidgets(
        'web billing uses role-appropriate customer identity for $role (fromOrder=$fromOrder)',
        (tester) async {
          final customers = _BillingCustomers();
          final bill = _bill(id: 'bill').copyWith(customerId: 'customer');
          final key = GlobalKey<WebBillFormContentState>();
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                authProvider.overrideWith(() => _RoleAuth(role)),
                customersRepositoryProvider.overrideWithValue(customers),
                ordersRepositoryProvider.overrideWithValue(_BillingOrders()),
                productsRepositoryProvider.overrideWithValue(
                  _BillingProducts(),
                ),
                quotesRepositoryProvider.overrideWithValue(_BillingQuotes()),
                billsRepositoryProvider.overrideWithValue(
                  _ListGetBills(listed: [bill], detailed: bill),
                ),
                productListProvider.overrideWith((ref, query) async => []),
              ],
              child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: Scaffold(
                  body: WebBillFormContent(
                    key: key,
                    orderId: fromOrder ? 'order' : null,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          if (!fromOrder) await key.currentState!.copyLastBill();
          await tester.pumpAndSettle();

          expect(customers.listBalances, isNotEmpty);
          expect(
            customers.listBalances,
            everyElement(role.canViewCustomerBalance),
          );
          expect(customers.getBalances, [role.canViewCustomerBalance]);
          expect(find.text('Directory Shop'), findsWidgets);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  test(
    'fetchLatestBillWithItems returns null when there are no bills',
    () async {
      final repo = _ListGetBills(listed: const []);
      expect(await fetchLatestBillWithItems(repo), isNull);
      expect(repo.getCalls, 0);
    },
  );

  test('fetchLatestBillWithItems uses list when items are present', () async {
    final withItems = _bill(
      id: 'b1',
      items: const [
        BillItem(
          id: 'i1',
          billId: 'b1',
          productId: 'p1',
          nameSnapshot: 'Rice',
          qty: 1,
        ),
      ],
    );
    final repo = _ListGetBills(listed: [withItems]);
    expect(await fetchLatestBillWithItems(repo), withItems);
    expect(repo.getCalls, 0);
  });

  test('fetchLatestBillWithItems loads get() when list omits items', () async {
    final header = _bill(id: 'b1');
    final detailed = _bill(
      id: 'b1',
      items: const [
        BillItem(
          id: 'i1',
          billId: 'b1',
          productId: 'p1',
          nameSnapshot: 'Rice',
          qty: 2,
        ),
      ],
    );
    final repo = _ListGetBills(listed: [header], detailed: detailed);
    final result = await fetchLatestBillWithItems(repo);
    expect(repo.getCalls, 1);
    expect(result!.items, hasLength(1));
    expect(result.items.single.qty, 2);
  });
}
