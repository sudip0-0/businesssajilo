import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/layout/adaptive_scaffold.dart';
import '../inventory/product_list_screen.dart';
import '../../core/ui/adaptive_sheet.dart';
import '../inventory/stock_in_picker_sheet.dart';
import '../notifications/notification_bell_action.dart';
import '../sync/sync_badge_action.dart';
import '../orders/fulfillment_list_screen.dart';
import '../orders/providers.dart';
import '../settings/account_section.dart';
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
    final fulfillmentCountAsync = ref.watch(fulfillmentActiveCountProvider);
    final pendingCount = fulfillmentCountAsync.when(
      data: (c) => '$c',
      loading: () => '…',
      error: (_, _) => '—',
    );

    return AdaptiveScaffold(
      selectedIndex: _index,
      onDestinationSelected: (i) => setState(() => _index = i),
      titles: [l10n.stock, l10n.fulfillment],
      actions: const [
        SyncBadgeAction(),
        NotificationBellAction(),
        AccountAction(),
        LogoutAction(),
      ],
      body: _index == 0
          ? const ProductListScreen(canEdit: false, canManageStock: true)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '$pendingCount · ${l10n.fulfillmentQueue}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const Expanded(child: FulfillmentListScreen()),
              ],
            ),
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              onPressed: () => showAdaptiveSheet(
                context: context,
                title: l10n.stockIn,
                child: const StockInPickerSheet(),
              ),
              icon: const Icon(Icons.add_box_outlined),
              label: Text(l10n.stockIn),
            )
          : null,
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.inventory_2_outlined),
          selectedIcon: const Icon(Icons.inventory_2),
          label: l10n.stock,
        ),
        NavigationDestination(
          icon: const Icon(Icons.local_shipping_outlined),
          selectedIcon: const Icon(Icons.local_shipping),
          label: l10n.fulfillment,
        ),
      ],
    );
  }
}
