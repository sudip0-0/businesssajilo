import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/layout/adaptive_scaffold.dart';
import '../../core/utils/money.dart';
import '../billing/bill_form_screen.dart';
import '../billing/bill_list_screen.dart';
import '../../core/theme/app_theme.dart';
import '../billing/providers.dart';
import '../customers/customer_list_screen.dart';
import '../customers/providers.dart';
import '../../core/ui/adaptive_sheet.dart';
import '../customers/record_payment_sheet.dart';
import '../inventory/product_list_screen.dart';
import '../notifications/notification_bell_action.dart';
import '../sync/sync_badge_action.dart';
import '../orders/order_queue_screen.dart';
import '../orders/providers.dart';
import 'logout_action.dart';
import 'role_dashboard.dart';
import '../settings/account_section.dart';

class SalesShell extends ConsumerStatefulWidget {
  const SalesShell({super.key});

  @override
  ConsumerState<SalesShell> createState() => _SalesShellState();
}

class _SalesShellState extends ConsumerState<SalesShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final totalDuesAsync = ref.watch(totalDuesProvider);
    final todaysBillsAsync = ref.watch(todaysBillCountProvider);
    final pendingOrdersAsync = ref.watch(pendingOrdersCountProvider);
    final quotesAsync = ref.watch(openQuotesCountProvider);

    final pages = [
      RoleDashboard(
        stats: [
          DashboardStat(
            icon: Icons.shopping_cart,
            label: l10n.pendingOrders,
            value: pendingOrdersAsync.when(
              data: (c) => '$c',
              loading: () => '…',
              error: (_, _) => '—',
            ),
          ),
          DashboardStat(
            icon: Icons.request_quote,
            label: l10n.quotes,
            value: quotesAsync.when(
              data: (c) => '$c',
              loading: () => '…',
              error: (_, _) => '—',
            ),
          ),
          DashboardStat(
            icon: Icons.receipt_long,
            label: l10n.todaysBills,
            value: todaysBillsAsync.when(
              data: (c) => '$c',
              loading: () => '…',
              error: (_, _) => '—',
            ),
          ),
          DashboardStat(
            icon: Icons.account_balance_wallet,
            label: l10n.dues,
            value: totalDuesAsync.when(
              data: (d) => formatNpr(Paisa(d), showPaisa: false),
              loading: () => '…',
              error: (_, _) => '—',
            ),
          ),
        ],
      ),
      const ProductListScreen(canEdit: false, canManageStock: false),
      const OrderQueueScreen(),
      const CustomerListScreen(canEdit: false, canRecordPayments: true),
      const BillListScreen(),
    ];

    return AdaptiveScaffold(
      selectedIndex: _index,
      onDestinationSelected: (i) => setState(() => _index = i),
      titles: [
        l10n.dashboard,
        l10n.stock,
        l10n.orders,
        l10n.customers,
        l10n.billing,
      ],
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          label: l10n.dashboard,
        ),
        NavigationDestination(
          icon: const Icon(Icons.inventory_2_outlined),
          selectedIcon: const Icon(Icons.inventory_2),
          label: l10n.stock,
        ),
        NavigationDestination(
          icon: const Icon(Icons.shopping_cart_outlined),
          selectedIcon: const Icon(Icons.shopping_cart),
          label: l10n.orders,
        ),
        NavigationDestination(
          icon: const Icon(Icons.storefront_outlined),
          selectedIcon: const Icon(Icons.storefront),
          label: l10n.customers,
        ),
        NavigationDestination(
          icon: const Icon(Icons.receipt_long_outlined),
          selectedIcon: const Icon(Icons.receipt_long),
          label: l10n.billing,
        ),
      ],
      actions: const [
        SyncBadgeAction(),
        NotificationBellAction(),
        AccountAction(),
        LogoutAction(),
      ],
      body: pages[_index],
      floatingActionButton: switch (_index) {
        3 => FloatingActionButton.extended(
          onPressed: () async {
            await showAdaptiveSheet<bool>(
              context: context,
              title: l10n.recordPayment,
              child: const RecordPaymentSheet(showCustomerPicker: true),
            );
            // Cache invalidation is handled by recordCustomerPayment.
          },
          icon: const Icon(Icons.payments_outlined),
          label: Text(l10n.recordPayment),
        ),
        4 => FloatingActionButton.extended(
          backgroundColor: BsColors.secondary,
          foregroundColor: BsColors.onSecondary,
          onPressed: () async {
            final saved = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => const BillFormScreen()),
            );
            if (saved == true) {
              ref.invalidate(billListProvider);
              ref.invalidate(todaysSalesProvider);
              ref.invalidate(todaysBillCountProvider);
              ref.invalidate(totalDuesProvider);
            }
          },
          icon: const Icon(Icons.add),
          label: Text(l10n.newBill),
        ),
        _ => null,
      },
    );
  }
}
