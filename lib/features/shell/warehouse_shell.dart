import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../inventory/product_list_screen.dart';
import '../inventory/stock_in_picker_sheet.dart';
import '../orders/fulfillment_list_screen.dart';
import '../orders/providers.dart';
import 'logout_action.dart';

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
    final fulfillmentAsync = ref.watch(fulfillmentQueueProvider);
    final pendingCount = fulfillmentAsync.when(
      data: (orders) => orders
          .where((o) => o.status.name != 'dispatched')
          .length
          .toString(),
      loading: () => '…',
      error: (_, _) => '—',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_index == 0 ? l10n.stock : l10n.fulfillment),
        actions: const [LogoutAction()],
      ),
      body: _index == 0
          ? const ProductListScreen(canEdit: false, canManageStock: true)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '$pendingCount ${l10n.fulfillmentQueue.toLowerCase()}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const Expanded(child: FulfillmentListScreen()),
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
