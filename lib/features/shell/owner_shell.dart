import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/utils/money.dart';
import '../billing/bill_form_screen.dart';
import '../billing/bill_list_screen.dart';
import '../billing/providers.dart';
import '../customers/add_customer_sheet.dart';
import '../customers/customer_list_screen.dart';
import '../customers/providers.dart';
import '../inventory/product_form_screen.dart';
import '../inventory/product_list_screen.dart';
import '../inventory/providers.dart';
import '../orders/order_queue_screen.dart';
import '../orders/providers.dart';
import '../notifications/notification_bell_action.dart';
import '../staff/add_member_sheet.dart';
import '../staff/staff_list_screen.dart';
import 'logout_action.dart';
import 'role_dashboard.dart';

class OwnerShell extends ConsumerStatefulWidget {
  const OwnerShell({super.key});

  @override
  ConsumerState<OwnerShell> createState() => _OwnerShellState();
}

class _OwnerShellState extends ConsumerState<OwnerShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lowStockAsync = ref.watch(lowStockCountProvider);
    final totalDuesAsync = ref.watch(totalDuesProvider);
    final todaysSalesAsync = ref.watch(todaysSalesProvider);
    final pendingOrdersAsync = ref.watch(pendingOrdersCountProvider);

    final pages = [
      RoleDashboard(
        stats: [
          (
            icon: Icons.payments,
            label: l10n.todaysSales,
            value: todaysSalesAsync.when(
              data: (d) => formatNpr(Paisa(d), showPaisa: false),
              loading: () => '…',
              error: (_, _) => '—',
            ),
          ),
          (
            icon: Icons.account_balance_wallet,
            label: l10n.totalDues,
            value: totalDuesAsync.when(
              data: (d) => formatNpr(Paisa(d), showPaisa: false),
              loading: () => '…',
              error: (_, _) => '—',
            ),
          ),
          (
            icon: Icons.inventory_2,
            label: l10n.lowStock,
            value: lowStockAsync.when(
              data: (c) => '$c',
              loading: () => '…',
              error: (_, _) => '—',
            ),
          ),
          (
            icon: Icons.shopping_cart,
            label: l10n.pendingOrders,
            value: pendingOrdersAsync.when(
              data: (c) => '$c',
              loading: () => '…',
              error: (_, _) => '—',
            ),
          ),
        ],
      ),
      const ProductListScreen(canEdit: true, canManageStock: true),
      const CustomerListScreen(canEdit: true, canRecordPayments: true),
      const BillListScreen(),
      const OrderQueueScreen(),
      const StaffListScreen(),
      Center(child: Text(l10n.settings)),
    ];

    final titles = [
      l10n.dashboard,
      l10n.inventory,
      l10n.customers,
      l10n.billing,
      l10n.orders,
      l10n.staffManagement,
      l10n.settings,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_index]),
        actions: const [NotificationBellAction(), LogoutAction()],
      ),
      body: pages[_index],
      floatingActionButton: switch (_index) {
        1 => FloatingActionButton.extended(
            onPressed: () async {
              final saved = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const ProductFormScreen()),
              );
              if (saved == true) {
                ref.invalidate(productListProvider);
                ref.invalidate(lowStockCountProvider);
              }
            },
            icon: const Icon(Icons.add),
            label: Text(l10n.addProduct),
          ),
        2 => FloatingActionButton.extended(
            onPressed: () async {
              final created = await showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const AddCustomerSheet(),
              );
              if (created == true) {
                ref.invalidate(customerListProvider);
                ref.invalidate(totalDuesProvider);
              }
            },
            icon: const Icon(Icons.person_add),
            label: Text(l10n.addCustomer),
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
        5 => FloatingActionButton.extended(
            onPressed: () async {
              final created = await showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const AddMemberSheet(),
              );
              if (created == true) ref.invalidate(staffListProvider);
            },
            icon: const Icon(Icons.person_add),
            label: Text(l10n.addMember),
          ),
        _ => null,
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: l10n.dashboard,
          ),
          NavigationDestination(
            icon: const Icon(Icons.inventory_2_outlined),
            selectedIcon: const Icon(Icons.inventory_2),
            label: l10n.inventory,
          ),
          NavigationDestination(
            icon: const Icon(Icons.storefront_outlined),
            selectedIcon: const Icon(Icons.storefront),
            label: l10n.customers,
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long),
            label: l10n.billing,
          ),
          NavigationDestination(
            icon: const Icon(Icons.shopping_cart_outlined),
            selectedIcon: const Icon(Icons.shopping_cart),
            label: l10n.orders,
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_outline),
            selectedIcon: const Icon(Icons.people),
            label: l10n.staff,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.settings,
          ),
        ],
      ),
    );
  }
}
