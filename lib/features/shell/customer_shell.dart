import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/layout/adaptive_scaffold.dart';
import '../../core/utils/money.dart';
import '../customers/customer_ledger_screen.dart';
import '../customers/providers.dart';
import '../notifications/notification_bell_action.dart';
import '../orders/catalog_screen.dart';
import '../orders/order_list_screen.dart';
import '../orders/providers.dart';
import 'logout_action.dart';
import 'role_dashboard.dart';

class CustomerShell extends ConsumerStatefulWidget {
  const CustomerShell({super.key});

  @override
  ConsumerState<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends ConsumerState<CustomerShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ownOrdersAsync = ref.watch(ownOrderListProvider);
    final ownCustomerAsync = ref.watch(ownCustomerProvider);

    final pages = [
      RoleDashboard(
        stats: [
          (icon: Icons.storefront, label: l10n.catalog, value: '—'),
          (
            icon: Icons.shopping_bag_outlined,
            label: l10n.myOrders,
            value: ownOrdersAsync.when(
              data: (o) => '${o.length}',
              loading: () => '…',
              error: (_, _) => '—',
            ),
          ),
          (
            icon: Icons.account_balance_wallet,
            label: l10n.myDues,
            value: ownCustomerAsync.when(
              data: (c) => c == null
                  ? '—'
                  : formatNpr(Paisa(c.balanceDue), showPaisa: false),
              loading: () => '…',
              error: (_, _) => '—',
            ),
          ),
        ],
      ),
      const CatalogScreen(),
      const OrderListScreen(ownOnly: true),
      const CustomerLedgerScreen(showBillHistory: true),
    ];

    return AdaptiveScaffold(
      selectedIndex: _index,
      onDestinationSelected: (i) => setState(() => _index = i),
      titles: [l10n.dashboard, l10n.catalog, l10n.myOrders, l10n.myDues],
      actions: const [NotificationBellAction(), LogoutAction()],
      body: IndexedStack(
        index: _index,
        children: pages,
      ),
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.dashboard_outlined),
          selectedIcon: const Icon(Icons.dashboard),
          label: l10n.dashboard,
        ),
        NavigationDestination(
          icon: const Icon(Icons.storefront_outlined),
          selectedIcon: const Icon(Icons.storefront),
          label: l10n.catalog,
        ),
        NavigationDestination(
          icon: const Icon(Icons.shopping_bag_outlined),
          selectedIcon: const Icon(Icons.shopping_bag),
          label: l10n.myOrders,
        ),
        NavigationDestination(
          icon: const Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: const Icon(Icons.account_balance_wallet),
          label: l10n.myDues,
        ),
      ],
    );
  }
}
