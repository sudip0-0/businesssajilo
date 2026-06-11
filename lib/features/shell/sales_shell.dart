import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import 'logout_action.dart';
import 'role_dashboard.dart';

class SalesShell extends StatelessWidget {
  const SalesShell({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboard),
        actions: const [LogoutAction()],
      ),
      body: RoleDashboard(
        stats: [
          (icon: Icons.shopping_cart, label: l10n.pendingOrders, value: '0'),
          (icon: Icons.request_quote, label: l10n.quotes, value: '0'),
          (icon: Icons.receipt_long, label: l10n.bills, value: '0'),
          (icon: Icons.account_balance_wallet, label: l10n.dues, value: 'रू 0'),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            label: l10n.dashboard,
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            label: l10n.billing,
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
