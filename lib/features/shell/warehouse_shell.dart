import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../inventory/product_list_screen.dart';
import '../inventory/stock_in_picker_sheet.dart';
import 'logout_action.dart';
import 'role_dashboard.dart';

/// Warehouse shell — no billing nav (hard product rule).
class WarehouseShell extends ConsumerStatefulWidget {
  const WarehouseShell({super.key});

  @override
  ConsumerState<WarehouseShell> createState() => _WarehouseShellState();
}

class _WarehouseShellState extends ConsumerState<WarehouseShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_index == 0 ? l10n.stock : l10n.fulfillment),
        actions: const [LogoutAction()],
      ),
      body: _index == 0
          ? const ProductListScreen(canEdit: false, canManageStock: true)
          : RoleDashboard(
              stats: [
                (icon: Icons.local_shipping, label: l10n.fulfillment, value: '0'),
              ],
            ),
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => const StockInPickerSheet(),
              ),
              icon: const Icon(Icons.add_box_outlined),
              label: Text(l10n.stockIn),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
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
