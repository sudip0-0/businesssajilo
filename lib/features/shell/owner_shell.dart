import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/layout/adaptive_scaffold.dart';
import '../../core/theme/app_theme.dart';
import '../billing/bill_form_screen.dart';
import '../billing/bill_list_screen.dart';
import '../billing/providers.dart';
import '../../core/ui/adaptive_sheet.dart';
import '../customers/add_customer_sheet.dart';
import '../customers/customer_list_screen.dart';
import '../customers/providers.dart';
import '../inventory/product_form_screen.dart';
import '../inventory/product_list_screen.dart';
import '../inventory/providers.dart';
import '../orders/order_queue_screen.dart';
import '../notifications/notification_bell_action.dart';
import '../reports/owner_dashboard.dart';
import '../reports/providers.dart';
import '../reports/reports_hub_screen.dart';
import '../settings/settings_screen.dart';
import '../onboarding/owner_onboarding_overlay.dart';
import '../sync/sync_badge_action.dart';
import '../staff/add_member_sheet.dart';
import '../staff/staff_list_screen.dart';

class OwnerShell extends ConsumerStatefulWidget {
  const OwnerShell({super.key});

  @override
  ConsumerState<OwnerShell> createState() => _OwnerShellState();
}

class _OwnerShellState extends ConsumerState<OwnerShell> {
  int _index = 0;

  // Mobile bottom nav: Dashboard, Inventory, Customers, Billing, More.
  static const _mobilePageIndexes = [0, 1, 2, 3];

  void _openOrders(bool wide) {
    if (wide) {
      setState(() => _index = 4);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text(AppLocalizations.of(context).orders)),
            body: const OrderQueueScreen(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final wide = isWideLayout(context);
    final pages = [
      OwnerDashboard(onOrdersTap: () => _openOrders(wide)),
      const ProductListScreen(canEdit: true, canManageStock: true),
      const CustomerListScreen(canEdit: true, canRecordPayments: true),
      const BillListScreen(),
      const OrderQueueScreen(),
      const StaffListScreen(),
      const ReportsHubScreen(),
      const SettingsScreen(),
    ];

    final titles = [
      l10n.dashboard,
      l10n.inventory,
      l10n.customers,
      l10n.billing,
      l10n.orders,
      l10n.staffManagement,
      l10n.reports,
      l10n.settings,
    ];

    final destinations = [
      NavigationDestination(
        icon: const Icon(Icons.dashboard_outlined),
        selectedIcon: const Icon(Icons.dashboard),
        label: l10n.dashboard,
      ),
      NavigationDestination(
        icon: const Icon(Icons.inventory_2_outlined),
        selectedIcon: const Icon(Icons.inventory_2),
        label: l10n.inventory,
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
      NavigationDestination(
        icon: const Icon(Icons.shopping_cart_outlined),
        selectedIcon: const Icon(Icons.shopping_cart),
        label: l10n.orders,
      ),
      NavigationDestination(
        icon: const Icon(Icons.people_outline),
        selectedIcon: const Icon(Icons.people),
        label: l10n.staff,
      ),
      NavigationDestination(
        icon: const Icon(Icons.assessment_outlined),
        selectedIcon: const Icon(Icons.assessment),
        label: l10n.reports,
      ),
      NavigationDestination(
        icon: const Icon(Icons.settings_outlined),
        selectedIcon: const Icon(Icons.settings),
        label: l10n.settings,
      ),
    ];

    // Mobile reduces to 5 destinations with a "More" page; the wide rail
    // keeps all 8 destinations.
    final mobileDestinations = [
      destinations[0],
      destinations[1],
      destinations[2],
      destinations[3],
      NavigationDestination(
        icon: const Icon(Icons.more_horiz_outlined),
        selectedIcon: const Icon(Icons.more_horiz),
        label: l10n.more,
      ),
    ];
    final mobileTitles = [
      titles[0],
      titles[1],
      titles[2],
      titles[3],
      l10n.more,
    ];

    // _index == -1 marks the mobile-only "More" page; fall back to the
    // dashboard if the layout becomes wide.
    final wideIndex = _index < 0 ? 0 : _index;
    final mobileIndex = _mobilePageIndexes.contains(_index)
        ? _mobilePageIndexes.indexOf(_index)
        : 4;
    final effectiveIndex = wide ? wideIndex : mobileIndex;
    final body = wide
        ? pages[wideIndex]
        : (mobileIndex < 4 ? pages[_index] : const _MorePage());

    return OwnerOnboardingOverlay(
      child: AdaptiveScaffold(
        selectedIndex: effectiveIndex,
        onDestinationSelected: (i) => setState(() {
          if (wide) {
            _index = i;
          } else {
            // "More" is a virtual page; mark it with a sentinel index.
            _index = i < 4 ? _mobilePageIndexes[i] : -1;
          }
        }),
        destinations: wide ? destinations : mobileDestinations,
        titles: wide ? titles : mobileTitles,
        actions: const [SyncBadgeAction(), NotificationBellAction()],
        body: body,
        floatingActionButton: switch (_index) {
          1 => FloatingActionButton.extended(
            backgroundColor: BsColors.secondary,
            foregroundColor: BsColors.onSecondary,
            onPressed: () async {
              final saved = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const ProductFormScreen()),
              );
              if (saved == true) {
                ref.invalidate(productListProvider);
                ref.invalidate(lowStockCountProvider);
                bumpInventoryRevision(ref);
              }
            },
            icon: const Icon(Icons.add),
            label: Text(l10n.addProduct),
          ),
          2 => FloatingActionButton.extended(
            backgroundColor: BsColors.secondary,
            foregroundColor: BsColors.onSecondary,
            onPressed: () async {
              final created = await showAdaptiveSheet<bool>(
                context: context,
                title: l10n.addCustomer,
                child: const AddCustomerSheet(),
              );
              if (created == true) {
                bumpCustomersRevision(ref);
                ref.invalidate(customerListProvider);
                ref.invalidate(totalDuesProvider);
              }
            },
            icon: const Icon(Icons.person_add),
            label: Text(l10n.addCustomer),
          ),
          3 => FloatingActionButton.extended(
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
                ref.invalidate(todaysSalesProvider);
                ref.invalidate(todaysBillCountProvider);
                ref.invalidate(totalDuesProvider);
                ref.invalidate(ownerDashboardStatsProvider);
              }
            },
            icon: const Icon(Icons.add),
            label: Text(l10n.newBill),
          ),
          5 => FloatingActionButton.extended(
            backgroundColor: BsColors.secondary,
            foregroundColor: BsColors.onSecondary,
            onPressed: () async {
              final created = await showAdaptiveSheet<bool>(
                context: context,
                title: l10n.addMember,
                child: const AddMemberSheet(),
              );
              if (created == true) ref.invalidate(staffListProvider);
            },
            icon: const Icon(Icons.person_add),
            label: Text(l10n.addMember),
          ),
          _ => null,
        },
      ),
    );
  }
}

/// Mobile-only page listing the secondary owner destinations.
class _MorePage extends StatelessWidget {
  const _MorePage();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = [
      (
        icon: Icons.shopping_cart_outlined,
        title: l10n.orders,
        body: const OrderQueueScreen(),
      ),
      (
        icon: Icons.people_outline,
        title: l10n.staffManagement,
        body: const StaffListScreen(),
      ),
      (
        icon: Icons.assessment_outlined,
        title: l10n.reports,
        body: const ReportsHubScreen(),
      ),
      (
        icon: Icons.settings_outlined,
        title: l10n.settings,
        body: const SettingsScreen(),
      ),
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: BsColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(BsRadii.lg),
              ),
              child: Icon(item.icon, color: BsColors.primary),
            ),
            title: Text(item.title),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: Text(item.title)),
                  body: item.body,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
