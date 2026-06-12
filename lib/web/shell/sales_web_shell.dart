import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/l10n/app_localizations.dart';
import '../layout/web_app_shell.dart';
import '../layout/web_sidebar.dart';

class SalesWebShell extends StatelessWidget {
  const SalesWebShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final items = [
      WebNavItem(
        label: l10n.dashboard,
        path: '/sales/dashboard',
        icon: PhosphorIconsRegular.squaresFour,
      ),
      WebNavItem(
        label: l10n.stock,
        path: '/sales/stock',
        icon: PhosphorIconsRegular.package,
      ),
      WebNavItem(
        label: l10n.orders,
        path: '/sales/orders',
        icon: PhosphorIconsRegular.shoppingCart,
      ),
      WebNavItem(
        label: l10n.customers,
        path: '/sales/customers',
        icon: PhosphorIconsRegular.storefront,
      ),
      WebNavItem(
        label: l10n.billing,
        path: '/sales/billing',
        icon: PhosphorIconsRegular.receipt,
      ),
    ];

    return WebAppShell(navItems: items, child: child);
  }
}
