import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/money.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/billing/providers.dart';
import '../../../features/customers/providers.dart';
import '../../../features/inventory/providers.dart';
import '../../../features/orders/providers.dart' as orders;
import '../../../features/reports/providers.dart';
import '../../../features/reports/sales_bar_chart.dart';
import '../web_page_scaffold.dart';
import '../../layout/web_bento_grid.dart';
import '../../ui/web_search_field.dart';
import '../../ui/web_stat_tile.dart';

class WebOwnerDashboardPage extends ConsumerWidget {
  const WebOwnerDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authProvider).value;
    final name = auth?.member?.displayName ?? '';
    final todaysSales = ref.watch(todaysSalesProvider);
    final totalDues = ref.watch(totalDuesProvider);
    final lowStock = ref.watch(lowStockCountProvider);
    final pendingOrders = ref.watch(orders.pendingOrdersCountProvider);
    final chartData = ref.watch(last7DaySalesProvider);

    return WebPageScaffold(
      title: l10n.dashboard,
      subtitle: l10n.welcomeUser(name),
      actions: [
        FilledButton.icon(
          onPressed: () => context.go('/owner/billing/new'),
          icon: Icon(PhosphorIconsRegular.receipt),
          label: Text(l10n.newBill),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () => context.go('/owner/inventory/new'),
          icon: Icon(PhosphorIconsRegular.plus),
          label: Text(l10n.addProduct),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(last7DaySalesProvider);
          ref.invalidate(todaysSalesProvider);
          ref.invalidate(totalDuesProvider);
          ref.invalidate(lowStockCountProvider);
          ref.invalidate(orders.pendingOrdersCountProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: WebBentoGrid(
            children: [
              WebStatTile(
                label: l10n.todaysSales,
                value: todaysSales.when(
                  data: (d) => formatNpr(Paisa(d), showPaisa: false),
                  loading: () => '…',
                  error: (_, _) => '—',
                ),
                icon: PhosphorIconsRegular.currencyDollar,
                onTap: () => context.go('/owner/reports/sales'),
              ),
              WebStatTile(
                label: l10n.totalDues,
                value: totalDues.when(
                  data: (d) => formatNpr(Paisa(d), showPaisa: false),
                  loading: () => '…',
                  error: (_, _) => '—',
                ),
                icon: PhosphorIconsRegular.wallet,
                onTap: () => context.go('/owner/reports/dues'),
              ),
              WebStatTile(
                label: l10n.lowStock,
                value: lowStock.when(
                  data: (c) => '$c',
                  loading: () => '…',
                  error: (_, _) => '—',
                ),
                icon: PhosphorIconsRegular.package,
                onTap: () => context.go('/owner/reports/stock'),
              ),
              WebStatTile(
                label: l10n.pendingOrders,
                value: pendingOrders.when(
                  data: (c) => '$c',
                  loading: () => '…',
                  error: (_, _) => '—',
                ),
                icon: PhosphorIconsRegular.shoppingCart,
                onTap: () => context.go('/owner/orders'),
              ),
              WebBentoTile(
                minHeight: 220,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.search, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    WebSearchField(
                      hint: l10n.filterProducts,
                      onChanged: (_) {},
                    ),
                    const Spacer(),
                    Text(
                      l10n.reports,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              WebBentoTile(
                minHeight: 280,
                child: chartData.when(
                  data: (data) => SalesBarChart(points: data),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
