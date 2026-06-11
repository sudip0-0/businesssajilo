import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/utils/money.dart';
import '../billing/bill_form_screen.dart';
import '../billing/bill_list_screen.dart';
import '../billing/providers.dart';
import '../customers/customer_list_screen.dart';
import '../customers/providers.dart';
import '../customers/record_payment_sheet.dart';
import '../inventory/product_list_screen.dart';
import 'logout_action.dart';
import 'role_dashboard.dart';

class SalesShell extends ConsumerStatefulWidget {
  const SalesShell({super.key});

  @override
  ConsumerState<SalesShell> createState() => _SalesShellState();
}

class _SalesShellState extends ConsumerState<SalesShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final totalDuesAsync = ref.watch(totalDuesProvider);
    final todaysBillsAsync = ref.watch(todaysBillCountProvider);
    final pages = [
      RoleDashboard(
        stats: [
          (icon: Icons.shopping_cart, label: l10n.pendingOrders, value: '0'),
          (icon: Icons.request_quote, label: l10n.quotes, value: '0'),
          (
            icon: Icons.receipt_long,
            label: l10n.todaysBills,
            value: todaysBillsAsync.when(
              data: (c) => '$c',
              loading: () => '…',
              error: (_, _) => '—',
            ),
          ),
          (
            icon: Icons.account_balance_wallet,
            label: l10n.dues,
            value: totalDuesAsync.when(
              data: (d) => formatNpr(Paisa(d), showPaisa: false),
              loading: () => '…',
              error: (_, _) => '—',
            ),
          ),
        ],
      ),
      const ProductListScreen(canEdit: false, canManageStock: false),
      const CustomerListScreen(canEdit: false, canRecordPayments: true),
      const BillListScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          switch (_index) {
            0 => l10n.dashboard,
            1 => l10n.stock,
            2 => l10n.customers,
            _ => l10n.billing,
          },
        ),
        actions: const [LogoutAction()],
      ),
      body: pages[_index],
      floatingActionButton: switch (_index) {
        2 => FloatingActionButton.extended(
            onPressed: () async {
              final saved = await showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const RecordPaymentSheet(showCustomerPicker: true),
              );
              if (saved == true) {
                ref.invalidate(customerListProvider);
                ref.invalidate(totalDuesProvider);
              }
            },
            icon: const Icon(Icons.payments_outlined),
            label: Text(l10n.recordPayment),
          ),
        3 => FloatingActionButton.extended(
            onPressed: () async {
              final saved = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const BillFormScreen()),
              );
              if (saved == true) {
                ref.invalidate(billListProvider);
                ref.invalidate(todaysSalesProvider);
                ref.invalidate(todaysBillCountProvider);
                ref.invalidate(totalDuesProvider);
              }
            },
            icon: const Icon(Icons.add),
            label: Text(l10n.newBill),
          ),
        _ => null,
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            label: l10n.dashboard,
          ),
          NavigationDestination(
            icon: const Icon(Icons.inventory_2_outlined),
            label: l10n.stock,
          ),
          NavigationDestination(
            icon: const Icon(Icons.storefront_outlined),
            label: l10n.customers,
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            label: l10n.billing,
          ),
        ],
      ),
    );
  }
}
