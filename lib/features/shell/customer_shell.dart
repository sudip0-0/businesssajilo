import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import 'logout_action.dart';
import 'role_dashboard.dart';

class CustomerShell extends StatelessWidget {
  const CustomerShell({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.catalog),
        actions: const [LogoutAction()],
      ),
      body: RoleDashboard(
        stats: [
          (icon: Icons.storefront, label: l10n.catalog, value: '—'),
          (icon: Icons.shopping_bag_outlined, label: l10n.myOrders, value: '0'),
          (icon: Icons.account_balance_wallet, label: l10n.myDues, value: 'रू 0'),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
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
