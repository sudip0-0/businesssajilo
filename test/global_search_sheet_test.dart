import 'package:businesssajilo/core/l10n/app_localizations.dart';
import 'package:businesssajilo/core/theme/app_theme.dart';
import 'package:businesssajilo/web/theme/web_theme.dart';
import 'package:businesssajilo/data/repositories/bills_repository.dart';
import 'package:businesssajilo/data/repositories/customers_repository.dart';
import 'package:businesssajilo/data/repositories/products_repository.dart';
import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/domain/models/bill.dart';
import 'package:businesssajilo/domain/models/customer.dart';
import 'package:businesssajilo/domain/models/member.dart';
import 'package:businesssajilo/domain/models/product.dart';
import 'package:businesssajilo/domain/models/session_state.dart';
import 'package:businesssajilo/features/auth/providers/auth_provider.dart';
import 'package:businesssajilo/features/search/global_search_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  for (final role in Role.values) {
    testWidgets(
      'global search sheet respects ${role.name} permissions and bill navigation',
      (tester) async {
        final calls = <String>[];
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, _) => Consumer(
                builder: (context, ref, _) => Scaffold(
                  body: TextButton(
                    onPressed: () => showGlobalSearch(context, ref),
                    child: const Text('Open search'),
                  ),
                ),
              ),
            ),
            GoRoute(
              path: '/${role.name}/billing',
              builder: (_, state) => Scaffold(
                body: Text('Bill ${state.uri.queryParameters['id']}'),
              ),
            ),
            GoRoute(
              path: '/customer/billing/:billId',
              builder: (_, state) => Scaffold(
                body: Text('Bill ${state.pathParameters['billId']}'),
              ),
            ),
          ],
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith(() => _Auth(role)),
              productsRepositoryProvider.overrideWithValue(_Products(calls)),
              customersRepositoryProvider.overrideWithValue(_Customers(calls)),
              billsRepositoryProvider.overrideWithValue(_Bills(calls)),
            ],
            child: MaterialApp.router(
              routerConfig: router,
              theme: kIsWeb ? WebTheme.light() : AppTheme.light(),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('en'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Open search'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'ri');
        await tester.pump(kGlobalSearchDebounce);
        await tester.pumpAndSettle();
        expect(
          find.text('Rice'),
          role == Role.customer ? findsNothing : findsOneWidget,
        );
        expect(
          find.text('Rice shop'),
          role == Role.owner || role == Role.sales
              ? findsOneWidget
              : findsNothing,
        );
        expect(find.text('BS-123'), findsOneWidget);
        expect(calls, switch (role) {
          Role.owner || Role.sales => ['products', 'customers:false', 'bills'],
          Role.warehouse => ['products', 'bills'],
          Role.customer => ['bills'],
        });
        if (kIsWeb) {
          await tester.tap(find.text('BS-123'));
          await tester.pumpAndSettle();
          expect(
            router.routeInformationProvider.value.uri.toString(),
            role == Role.customer
                ? '/customer/billing/b1'
                : '/${role.name}/billing?id=b1',
          );
          expect(find.text('Bill b1'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        router.dispose();
      },
    );
  }
}

class _Auth extends AuthController {
  _Auth(this.role);
  final Role role;
  @override
  AsyncValue<SessionState> build() => AsyncValue.data(
    SessionState(
      member: Member(
        id: 'm1',
        businessId: 'business',
        authUserId: 'user',
        role: role,
        displayName: role.name,
      ),
    ),
  );
}

class _Products implements ProductsRepository {
  _Products(this.calls);
  final List<String> calls;
  @override
  Future<List<Product>> list({
    bool activeOnly = true,
    int offset = 0,
    int? limit,
    String? query,
    ProductStockFilter stockFilter = ProductStockFilter.all,
  }) async {
    calls.add('products');
    return [const Product(id: 'p1', businessId: 'business', name: 'Rice')];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Customers implements CustomersRepository {
  _Customers(this.calls);
  final List<String> calls;
  @override
  Future<List<Customer>> list({
    int offset = 0,
    int? limit,
    String? query,
    bool includeBalances = true,
    CustomerBalanceFilter balanceFilter = CustomerBalanceFilter.all,
  }) async {
    calls.add('customers:$includeBalances');
    return [
      const Customer(
        id: 'c1',
        businessId: 'business',
        memberId: 'cm1',
        shopName: 'Rice shop',
      ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Bills implements BillsRepository {
  _Bills(this.calls);
  final List<String> calls;
  @override
  Future<List<Bill>> search(
    String query, {
    int limit = 50,
    int offset = 0,
    BillStatus? status,
  }) async {
    calls.add('bills');
    return [
      const Bill(
        id: 'b1',
        businessId: 'business',
        billNo: 'BS-123',
        status: BillStatus.due,
        createdBy: 'm1',
      ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
