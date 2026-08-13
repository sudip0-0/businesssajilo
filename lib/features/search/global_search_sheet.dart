import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
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
    if (query.trim().length < 2) {
      return Center(child: Text(AppLocalizations.of(context).globalSearchHint));
    }
    return _Results(query: query, ref: ref);
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.query, required this.ref});

  final String query;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final q = query.trim();
    final role = ref.read(authProvider).value?.member?.role;

    return FutureBuilder(
      future: Future.wait<Object>([
        ref.read(productsRepositoryProvider).list(query: q, limit: 8),
        ref.read(customersRepositoryProvider).list(query: q, limit: 8),
        ref.read(billsRepositoryProvider).search(q, limit: 8),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final products = snapshot.data![0] as List<Product>;
        final customers = snapshot.data![1] as List<Customer>;
        final bills = snapshot.data![2] as List<Bill>;
        if (products.isEmpty && customers.isEmpty && bills.isEmpty) {
          return Center(child: Text(l10n.noMatchingResults));
        }
        return ListView(
          children: [
            if (products.isNotEmpty)
              ListTile(title: Text(l10n.products), dense: true),
            for (final p in products)
              ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: Text(p.name),
                onTap: () {
                  Navigator.pop(context);
                  _openProduct(context, p.id, role: role);
                },
              ),
            if (customers.isNotEmpty)
              ListTile(title: Text(l10n.customers), dense: true),
            for (final c in customers)
              ListTile(
                leading: const Icon(Icons.storefront_outlined),
                title: Text(c.shopName),
                onTap: () {
                  Navigator.pop(context);
                  _openCustomer(context, c.id, role: role);
                },
              ),
            if (bills.isNotEmpty)
              ListTile(title: Text(l10n.bills), dense: true),
            for (final b in bills)
              ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: Text(b.billNo),
                subtitle: Text(
                  formatNpr(Paisa(b.grandTotal), showPaisa: false),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _openBill(context, b.id);
                },
              ),
          ],
        );
      },
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
