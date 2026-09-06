import 'package:businesssajilo/core/ui/debounced_list_search.dart';
import 'package:businesssajilo/features/search/global_search_sheet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:businesssajilo/data/repositories/products_repository.dart';
import 'package:businesssajilo/data/repositories/customers_repository.dart';
import 'package:businesssajilo/data/repositories/bills_repository.dart';
import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/domain/models/product.dart';
import 'package:businesssajilo/domain/models/customer.dart';
import 'package:businesssajilo/domain/models/bill.dart';

void main() {
  for (final role in <Role?>[...Role.values, null]) {
    test(
      'global search fetches only authorized categories for $role',
      () async {
        final calls = <String>[];
        final hit = await searchGlobalCatalog(
          products: _Products(calls),
          customers: _Customers(calls),
          bills: _Bills(calls),
          query: '  rice  ',
          role: role,
          limit: 3,
        );
        expect(calls, switch (role) {
          Role.owner || Role.sales => [
            'products:rice:3',
            'customers:rice:3:false',
            'bills:rice:3',
          ],
          Role.warehouse => ['products:rice:3', 'bills:rice:3'],
          Role.customer => ['bills:rice:3'],
          null => <String>[],
        });
        expect(hit.isEmpty, isTrue);
      },
    );

    test('short global searches make no requests for $role', () async {
      final calls = <String>[];
      await searchGlobalCatalog(
        products: _Products(calls),
        customers: _Customers(calls),
        bills: _Bills(calls),
        query: ' a ',
        role: role,
      );
      expect(calls, isEmpty);
    });
  }

  test('staff selection URLs use the router id query contract', () {
    for (final role in [Role.owner, Role.sales, Role.warehouse]) {
      final base = '/${role.name}';
      final productSection = role == Role.owner ? 'inventory' : 'stock';
      expect(
        globalSearchWebLocation(role, GlobalSearchCategory.products, 'p1'),
        '$base/$productSection?id=p1',
      );
      expect(
        globalSearchWebLocation(role, GlobalSearchCategory.bills, 'b1'),
        '$base/billing?id=b1',
      );
      expect(
        globalSearchWebLocation(role, GlobalSearchCategory.customers, 'c1'),
        role == Role.warehouse ? null : '$base/customers?id=c1',
      );
    }
    final uri = Uri.parse(
      globalSearchWebLocation(
        Role.sales,
        GlobalSearchCategory.bills,
        'id &/?',
      )!,
    );
    expect(uri.queryParameters, {'id': 'id &/?'});
  });

  test('customer and missing membership cannot open staff search details', () {
    expect(
      globalSearchWebLocation(Role.customer, GlobalSearchCategory.bills, 'b1'),
      '/customer/billing/b1',
    );
    for (final category in GlobalSearchCategory.values) {
      expect(globalSearchWebLocation(null, category, 'id'), isNull);
      if (category != GlobalSearchCategory.bills) {
        expect(globalSearchWebLocation(Role.customer, category, 'id'), isNull);
      }
    }
  });
  test(
    'DebouncedListSearchController discards stale in-flight results',
    () async {
      var calls = 0;
      final started = <String>[];
      final controller = DebouncedListSearchController<String>(
        debounce: const Duration(milliseconds: 20),
        onChanged: () {},
        search: (query) async {
          calls += 1;
          started.add(query);
          await Future<void>.delayed(
            Duration(milliseconds: query == 'ab' ? 80 : 10),
          );
          return [query];
        },
      );

      controller.onQueryChanged('ab');
      await Future<void>.delayed(const Duration(milliseconds: 30));
      controller.onQueryChanged('abc');
      await Future<void>.delayed(const Duration(milliseconds: 120));

      expect(started, ['ab', 'abc']);
      expect(calls, 2);
      expect(controller.results, ['abc']);
      expect(controller.phase, ListSearchPhase.data);
      controller.dispose();
    },
  );

  test('global search min chars is two', () {
    expect(kGlobalSearchMinChars, 2);
    expect(kGlobalSearchDebounce, const Duration(milliseconds: 300));
  });
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
    calls.add('products:$query:$limit');
    return [];
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
    calls.add('customers:$query:$limit:$includeBalances');
    return [];
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
    calls.add('bills:$query:$limit');
    return [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
