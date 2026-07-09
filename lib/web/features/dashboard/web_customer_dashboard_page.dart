import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/money.dart';
import '../../../features/customers/providers.dart';
import '../../../features/orders/providers.dart';
import '../../layout/web_bento_grid.dart';
import '../../ui/web_stat_tile.dart';
import '../web_page_scaffold.dart';

class WebCustomerDashboardPage extends ConsumerWidget {
  const WebCustomerDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ownOrdersCount = ref.watch(ownOrderCountProvider);
    final ownCustomer = ref.watch(ownCustomerProvider);

    return WebPageScaffold(
      title: l10n.dashboard,
      actions: [
        FilledButton.icon(
          onPressed: () => context.go('/customer/catalog'),
          icon: Icon(PhosphorIconsRegular.storefront),
          label: Text(l10n.catalog),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(ownOrderCountProvider);
          ref.invalidate(ownCustomerProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: WebBentoGrid(
            children: [
              WebStatTile(
                label: l10n.myOrders,
                value: ownOrdersCount.when(
                  data: (c) => '$c',
                  loading: () => '…',
                  error: (_, _) => '—',
                ),
                icon: PhosphorIconsRegular.shoppingBag,
                onTap: () => context.go('/customer/orders'),
              ),
              WebStatTile(
                label: l10n.myDues,
                value: ownCustomer.when(
                  data: (c) => c == null
                      ? '—'
                      : formatNpr(Paisa(c.balanceDue), showPaisa: false),
                  loading: () => '…',
                  error: (_, _) => '—',
                ),
                icon: PhosphorIconsRegular.wallet,
                onTap: () => context.go('/customer/dues'),
              ),
              WebBentoTile(
                minHeight: 160,
                onTap: () => context.go('/customer/catalog'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      PhosphorIconsRegular.storefront,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.catalog,
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
              WebBentoTile(
                minHeight: 160,
                onTap: () => context.go('/customer/orders'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      PhosphorIconsRegular.package,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.myOrders,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.orderItems,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              WebBentoTile(
                minHeight: 160,
                onTap: () => context.go('/customer/dues'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      PhosphorIconsRegular.receipt,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.myDues,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.ledger,
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
