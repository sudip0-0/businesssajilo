import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/testing/integration_keys.dart';
import '../../features/orders/providers.dart';
import '../layout/web_app_shell.dart';
import '../layout/web_sidebar.dart';

class OwnerWebShell extends ConsumerWidget {
  const OwnerWebShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final pendingOrders = ref.watch(pendingOrdersCountProvider);

    final items = [
      WebNavItem(
        label: l10n.dashboard,
        path: '/owner/dashboard',
        icon: PhosphorIconsRegular.squaresFour,
      ),
      WebNavItem(
        label: l10n.inventory,
        path: '/owner/inventory',
        icon: PhosphorIconsRegular.package,
      ),
      WebNavItem(
        label: l10n.billing,
        path: '/owner/billing',
        icon: PhosphorIconsRegular.receipt,
      ),
      WebNavItem(
        label: l10n.customers,
        path: '/owner/customers',
        icon: PhosphorIconsRegular.storefront,
      ),
      WebNavItem(
        label: l10n.orders,
        path: '/owner/orders',
        icon: PhosphorIconsRegular.shoppingCart,
        badge: pendingOrders.when(
          data: (c) => c > 0 ? '$c' : null,
          loading: () => null,
          error: (_, _) => null,
        ),
      ),
      WebNavItem(
        label: l10n.reports,
        path: '/owner/reports',
        icon: PhosphorIconsRegular.chartBar,
      ),
      WebNavItem(
        label: l10n.staffManagement,
        path: '/owner/staff',
        icon: PhosphorIconsRegular.users,
      ),
      WebNavItem(
        label: l10n.settings,
        path: '/owner/settings',
        icon: PhosphorIconsRegular.gear,
      ),
    ];

    return WebAppShell(
      navItems: items,
      sidebarFooter: _CreateBillButton(
        label: l10n.createNewBill,
        onPressed: () => context.go('/owner/billing/new'),
      ),
      child: child,
    );
  }
}

class _CreateBillButton extends StatelessWidget {
  const _CreateBillButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        key: IntegrationKeys.sidebarCreateBill,
        onPressed: onPressed,
        icon: Icon(PhosphorIconsRegular.plus, size: 18),
        label: Text(label),
      ),
    );
  }
}
