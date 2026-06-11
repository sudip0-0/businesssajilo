import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../customers/customer_ledger_screen.dart';
import 'logout_action.dart';
import 'role_dashboard.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pages = [
      RoleDashboard(
        stats: [
          (icon: Icons.storefront, label: l10n.catalog, value: '—'),
          (icon: Icons.shopping_bag_outlined, label: l10n.myOrders, value: '0'),
          (icon: Icons.account_balance_wallet, label: l10n.myDues, value: '—'),
        ],
      ),
      const Center(child: Text('Orders — Phase 5')),
      const CustomerLedgerScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          switch (_index) {
            0 => l10n.catalog,
            1 => l10n.myOrders,
            _ => l10n.myDues,
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
            icon: const Icon(Icons.storefront_outlined),
            label: l10n.catalog,
          ),
          NavigationDestination(
            icon: const Icon(Icons.shopping_bag_outlined),
            label: l10n.myOrders,
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            label: l10n.myDues,
          ),
        ],
      ),
    );
  }
}
