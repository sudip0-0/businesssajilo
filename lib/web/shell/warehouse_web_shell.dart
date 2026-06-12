import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/l10n/app_localizations.dart';
import '../../features/orders/providers.dart';
import '../layout/web_app_shell.dart';
import '../layout/web_sidebar.dart';

class WarehouseWebShell extends ConsumerWidget {
  const WarehouseWebShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final fulfillment = ref.watch(fulfillmentQueueProvider);

    final items = [
      WebNavItem(
        label: l10n.stock,
        path: '/warehouse/stock',
        icon: PhosphorIconsRegular.package,
      ),
      WebNavItem(
        label: l10n.fulfillment,
        path: '/warehouse/fulfillment',
        icon: PhosphorIconsRegular.truck,
        badge: fulfillment.when(
          data: (q) => q.isNotEmpty ? '${q.length}' : null,
          loading: () => null,
          error: (_, _) => null,
        ),
      ),
    ];

    return WebAppShell(navItems: items, child: child);
  }
}
