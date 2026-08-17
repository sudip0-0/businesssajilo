import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/layout/adaptive_scaffold.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/adaptive_sheet.dart';
import '../billing/bill_form_screen.dart';
import '../billing/bill_list_screen.dart';
import '../billing/providers.dart';
import '../inventory/product_list_screen.dart';
import '../inventory/stock_in_picker_sheet.dart';
import '../notifications/notification_bell_action.dart';
import '../settings/account_section.dart';
import '../sync/sync_badge_action.dart';
import 'logout_action.dart';

/// Warehouse shell — stock + billing (no customer balance / payments).
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

    final pages = [
      const ProductListScreen(canEdit: false, canManageStock: true),
      const BillListScreen(),
    ];

    return AdaptiveScaffold(
      selectedIndex: _index,
      onDestinationSelected: (i) => setState(() => _index = i),
      titles: [l10n.stock, l10n.billing],
      actions: const [
        SyncBadgeAction(),
        NotificationBellAction(),
        AccountAction(),
        LogoutAction(),
      ],
      body: IndexedStack(index: _index, children: pages),
      floatingActionButton: switch (_index) {
        0 => FloatingActionButton.extended(
          onPressed: () => showAdaptiveSheet(
            context: context,
            title: l10n.stockIn,
            child: const StockInPickerSheet(),
          ),
          icon: const Icon(Icons.add_box_outlined),
          label: Text(l10n.stockIn),
        ),
        1 => FloatingActionButton.extended(
          backgroundColor: BsColors.secondary,
          foregroundColor: BsColors.onSecondary,
          onPressed: () async {
            final saved = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => const BillFormScreen()),
            );
            if (saved == true) {
              bumpBillingRevision(ref);
              ref.invalidate(billListProvider);
            }
          },
          icon: const Icon(Icons.add),
          label: Text(l10n.newBill),
        ),
        _ => null,
      },
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.inventory_2_outlined),
          selectedIcon: const Icon(Icons.inventory_2),
          label: l10n.stock,
          tooltip: l10n.stock,
        ),
        NavigationDestination(
          icon: const Icon(Icons.receipt_long_outlined),
          selectedIcon: const Icon(Icons.receipt_long),
          label: l10n.billing,
          tooltip: l10n.billing,
        ),
      ],
    );
  }
}
