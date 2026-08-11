import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/money.dart';
import '../../../features/customers/providers.dart';
import '../../../features/orders/providers.dart';
import '../../../features/reports/dashboard/dashboard_invalidation.dart';
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
          icon: const Icon(PhosphorIconsRegular.storefront),
          label: Text(l10n.catalog),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: () async {
          invalidateCustomerDashboardWidget(ref);
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
                height: 188,
                onTap: () => context.go('/customer/catalog'),
                child: _CustomerShortcutContent(
                  icon: PhosphorIconsRegular.storefront,
                  title: l10n.catalog,
                  subtitle: l10n.filterProducts,
                ),
              ),
              WebBentoTile(
                height: 188,
                onTap: () => context.go('/customer/orders'),
                child: _CustomerShortcutContent(
                  icon: PhosphorIconsRegular.package,
                  title: l10n.myOrders,
                  subtitle: l10n.orderItems,
                ),
              ),
              WebBentoTile(
                height: 188,
                onTap: () => context.go('/customer/dues'),
                child: _CustomerShortcutContent(
                  icon: PhosphorIconsRegular.receipt,
                  title: l10n.myDues,
                  subtitle: l10n.ledger,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerShortcutContent extends StatelessWidget {
  const _CustomerShortcutContent({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}
