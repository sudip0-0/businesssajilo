import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../features/inventory/providers.dart';
import '../../../features/orders/providers.dart';
import '../../layout/web_bento_grid.dart';
import '../../ui/web_stat_tile.dart';
import '../web_page_scaffold.dart';

class WebWarehouseDashboardPage extends ConsumerWidget {
  const WebWarehouseDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final fulfillmentCountAsync = ref.watch(fulfillmentActiveCountProvider);
    final lowStock = ref.watch(lowStockCountProvider);

    return WebPageScaffold(
      title: l10n.dashboard,
      actions: [
        OutlinedButton.icon(
          onPressed: () => context.go('/warehouse/stock'),
          icon: Icon(PhosphorIconsRegular.package),
          label: Text(l10n.stock),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(fulfillmentActiveCountProvider);
          ref.invalidate(lowStockCountProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: WebBentoGrid(
            columns: 2,
            children: [
              WebStatTile(
                label: l10n.fulfillmentQueue,
                value: fulfillmentCountAsync.when(
                  data: (c) => '$c',
                  loading: () => '…',
                  error: (_, _) => '—',
                ),
                icon: PhosphorIconsRegular.truck,
                onTap: () => context.go('/warehouse/fulfillment'),
              ),
              WebStatTile(
                label: l10n.lowStock,
                value: lowStock.when(
                  data: (c) => '$c',
                  loading: () => '…',
                  error: (_, _) => '—',
                ),
                icon: PhosphorIconsRegular.warning,
                onTap: () => context.go('/warehouse/stock'),
              ),
              WebBentoTile(
                minHeight: 180,
                onTap: () => context.go('/warehouse/fulfillment'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      PhosphorIconsRegular.listChecks,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.fulfillment,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.fulfillmentQueue,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              WebBentoTile(
                minHeight: 180,
                onTap: () => context.go('/warehouse/stock'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      PhosphorIconsRegular.warehouse,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.stock,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.filterProducts,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
