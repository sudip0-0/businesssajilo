import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/layout/adaptive_scaffold.dart';
import '../inventory/product_list_screen.dart';
import '../../core/ui/adaptive_sheet.dart';
import '../inventory/stock_in_picker_sheet.dart';
import '../notifications/notification_bell_action.dart';
import '../sync/sync_badge_action.dart';
import '../settings/account_section.dart';
import 'logout_action.dart';

/// Warehouse shell — stock only (orders no longer use a fulfillment queue).
class WarehouseShell extends ConsumerStatefulWidget {
  const WarehouseShell({super.key});

  @override
  ConsumerState<WarehouseShell> createState() => _WarehouseShellState();
}

class _WarehouseShellState extends ConsumerState<WarehouseShell> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AdaptiveScaffold(
      selectedIndex: 0,
      onDestinationSelected: (_) {},
      titles: [l10n.stock],
      actions: const [
        SyncBadgeAction(),
        NotificationBellAction(),
        AccountAction(),
        LogoutAction(),
      ],
      body: const ProductListScreen(canEdit: false, canManageStock: true),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAdaptiveSheet(
          context: context,
          title: l10n.stockIn,
          child: const StockInPickerSheet(),
        ),
        icon: const Icon(Icons.add_box_outlined),
        label: Text(l10n.stockIn),
      ),
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.inventory_2_outlined),
          selectedIcon: const Icon(Icons.inventory_2),
          label: l10n.stock,
          tooltip: l10n.stock,
        ),
      ],
    );
  }
}
