import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import 'logout_action.dart';
import 'role_dashboard.dart';

/// Warehouse shell — no billing nav (hard product rule).
class WarehouseShell extends StatelessWidget {
  const WarehouseShell({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.inventory),
        actions: const [LogoutAction()],
      ),
      body: RoleDashboard(
        stats: [
          (icon: Icons.local_shipping, label: l10n.fulfillment, value: '0'),
          (icon: Icons.inventory_2, label: l10n.lowStock, value: '0'),
          (icon: Icons.add_box_outlined, label: l10n.stockIn, value: '—'),
          (icon: Icons.warehouse_outlined, label: l10n.stock, value: '—'),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.inventory_2_outlined),
            label: l10n.stock,
          ),
          NavigationDestination(
            icon: const Icon(Icons.local_shipping_outlined),
            label: l10n.fulfillment,
          ),
        ],
      ),
    );
  }
}
