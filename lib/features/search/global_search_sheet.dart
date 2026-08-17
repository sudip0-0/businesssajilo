import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/ui/error_state.dart';
import '../../core/utils/money.dart';
import '../../data/repositories/bills_repository.dart';
import '../../data/repositories/customers_repository.dart';
import '../../data/repositories/products_repository.dart';
import '../../domain/enums.dart';
import '../../domain/models/bill.dart';
import '../../domain/models/customer.dart';
import '../../domain/models/product.dart';
import '../auth/providers/auth_provider.dart';
import '../billing/bill_detail_screen.dart';
import '../customers/customer_detail_screen.dart';
import '../inventory/product_detail_screen.dart';

const kGlobalSearchDebounce = Duration(milliseconds: 300);
const kGlobalSearchMinChars = 2;

Future<void> showGlobalSearch(BuildContext context, WidgetRef ref) {
  return showSearch(context: context, delegate: _GlobalSearchDelegate(ref));
}

class _GlobalSearchDelegate extends SearchDelegate<void> {
  _GlobalSearchDelegate(this.ref);

  final WidgetRef ref;

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _Results(query: query, ref: ref);

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.trim().length < kGlobalSearchMinChars) {
      return Center(child: Text(AppLocalizations.of(context).globalSearchHint));
    }
    return _Results(query: query, ref: ref);
  }
}

class GlobalSearchHit {
  const GlobalSearchHit({
    required this.products,
    required this.customers,
    required this.bills,
  });

  final List<Product> products;
  final List<Customer> customers;
  final List<Bill> bills;

  bool get isEmpty => products.isEmpty && customers.isEmpty && bills.isEmpty;
}

Future<GlobalSearchHit> searchGlobalCatalog({
  required ProductsRepository products,
  required CustomersRepository customers,
  required BillsRepository bills,
  required String query,
  int limit = 8,
}) async {
  final q = query.trim();
  final results = await Future.wait<Object>([
    products.list(query: q, limit: limit),
    customers.list(query: q, limit: limit),
    bills.search(q, limit: limit),
  ]);
  return GlobalSearchHit(
    products: results[0] as List<Product>,
    customers: results[1] as List<Customer>,
    bills: results[2] as List<Bill>,
  );
}

class _Results extends StatefulWidget {
  const _Results({required this.query, required this.ref});

  final String query;
  final WidgetRef ref;

  @override
  State<_Results> createState() => _ResultsState();
}

class _ResultsState extends State<_Results> {
  Timer? _debounce;
  int _requestId = 0;
  Object? _error;
  GlobalSearchHit? _hit;
  var _loading = false;

  @override
  void initState() {
    super.initState();
    _scheduleSearch();
  }

  @override
  void didUpdateWidget(covariant _Results oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _scheduleSearch();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _scheduleSearch() {
    _debounce?.cancel();
    final q = widget.query.trim();
    if (q.length < kGlobalSearchMinChars) {
      setState(() {
        _hit = null;
        _error = null;
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    _debounce = Timer(kGlobalSearchDebounce, _runSearch);
  }

  Future<void> _runSearch() async {
    final id = ++_requestId;
    final q = widget.query.trim();
    try {
      final hit = await searchGlobalCatalog(
        products: widget.ref.read(productsRepositoryProvider),
        customers: widget.ref.read(customersRepositoryProvider),
        bills: widget.ref.read(billsRepositoryProvider),
        query: q,
      );
      if (!mounted || id != _requestId) return;
      setState(() {
        _hit = hit;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final role = widget.ref.read(authProvider).value?.member?.role;

    if (_loading && _hit == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _hit == null) {
      return ErrorState(onRetry: _runSearch);
    }
    final hit = _hit;
    if (hit == null || hit.isEmpty) {
      return Center(child: Text(l10n.noMatchingResults));
    }
    return ListView(
      children: [
        if (hit.products.isNotEmpty)
          ListTile(title: Text(l10n.products), dense: true),
        for (final p in hit.products)
          ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: Text(p.name),
            onTap: () {
              Navigator.pop(context);
              _openProduct(context, p.id, role: role);
            },
          ),
        if (hit.customers.isNotEmpty)
          ListTile(title: Text(l10n.customers), dense: true),
        for (final c in hit.customers)
          ListTile(
            leading: const Icon(Icons.storefront_outlined),
            title: Text(c.shopName),
            onTap: () {
              Navigator.pop(context);
              _openCustomer(context, c.id, role: role);
            },
          ),
        if (hit.bills.isNotEmpty)
          ListTile(title: Text(l10n.bills), dense: true),
        for (final b in hit.bills)
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: Text(b.billNo),
            subtitle: Text(formatNpr(Paisa(b.grandTotal), showPaisa: false)),
            onTap: () {
              Navigator.pop(context);
              _openBill(context, b.id);
            },
          ),
      ],
    );
  }
}

void _openProduct(BuildContext context, String id, {Role? role}) {
  if (kIsWeb) {
    final prefix = role == Role.sales ? '/sales/stock' : '/owner/inventory';
    context.go('$prefix/$id');
    return;
  }
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ProductDetailScreen(
        productId: id,
        canManageStock: role == Role.owner || role == Role.warehouse,
        canEditProduct: role == Role.owner || role == Role.sales,
      ),
    ),
  );
}

void _openCustomer(BuildContext context, String id, {Role? role}) {
  if (kIsWeb) {
    final prefix = role == Role.sales ? '/sales' : '/owner';
    context.go('$prefix/customers/$id');
    return;
  }
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => CustomerDetailScreen(
        customerId: id,
        canEdit: role == Role.owner,
        canRecordPayments: role == Role.owner || role == Role.sales,
      ),
    ),
  );
}

void _openBill(BuildContext context, String id) {
  if (kIsWeb) {
    context.go('/owner/billing/$id');
    return;
  }
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => BillDetailScreen(billId: id)),
  );
}
