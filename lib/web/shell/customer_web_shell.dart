import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/l10n/app_localizations.dart';
import '../layout/web_app_shell.dart';
import '../layout/web_sidebar.dart';

class CustomerWebShell extends StatelessWidget {
  const CustomerWebShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final items = [
      WebNavItem(
        label: l10n.dashboard,
        path: '/customer/dashboard',
        icon: PhosphorIconsRegular.squaresFour,
      ),
      WebNavItem(
        label: l10n.catalog,
        path: '/customer/catalog',
        icon: PhosphorIconsRegular.storefront,
      ),
      WebNavItem(
        label: l10n.myOrders,
        path: '/customer/orders',
        icon: PhosphorIconsRegular.shoppingBag,
      ),
      WebNavItem(
        label: l10n.myDues,
        path: '/customer/dues',
        icon: PhosphorIconsRegular.wallet,
      ),
    ];

    return WebAppShell(navItems: items, child: child);
  }
}
