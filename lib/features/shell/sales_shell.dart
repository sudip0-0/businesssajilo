import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../inventory/product_list_screen.dart';
import 'logout_action.dart';
import 'role_dashboard.dart';

class SalesShell extends StatefulWidget {
  const SalesShell({super.key});

  @override
  State<SalesShell> createState() => _SalesShellState();
}

class _SalesShellState extends State<SalesShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pages = [
      RoleDashboard(
        stats: [
          (icon: Icons.shopping_cart, label: l10n.pendingOrders, value: '0'),
          (icon: Icons.request_quote, label: l10n.quotes, value: '0'),
          (icon: Icons.receipt_long, label: l10n.bills, value: '0'),
          (icon: Icons.account_balance_wallet, label: l10n.dues, value: 'रू 0'),
        ],
      ),
      const ProductListScreen(canEdit: false, canManageStock: false),
      const Center(child: Text('Orders — Phase 5')),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          switch (_index) {
            0 => l10n.dashboard,
            1 => l10n.stock,
            _ => l10n.orders,
          },
        ),
        actions: const [LogoutAction()],
      ),
      body: pages[_index],
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
            icon: const Icon(Icons.shopping_cart_outlined),
            label: l10n.orders,
          ),
        ],
      ),
    );
  }
}
