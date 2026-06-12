import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/money.dart';
import '../../../features/billing/providers.dart';
import '../../../features/customers/providers.dart';
import '../../../features/orders/providers.dart';
import '../../layout/web_bento_grid.dart';
import '../../ui/web_stat_tile.dart';
import '../web_page_scaffold.dart';

class WebSalesDashboardPage extends ConsumerWidget {
  const WebSalesDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final pendingOrders = ref.watch(pendingOrdersCountProvider);
    final quotes = ref.watch(openQuotesCountProvider);
    final todaysBills = ref.watch(todaysBillCountProvider);
    final totalDues = ref.watch(totalDuesProvider);

    return WebPageScaffold(
      title: l10n.dashboard,
      actions: [
        FilledButton.icon(
          onPressed: () => context.go('/sales/billing/new'),
          icon: Icon(PhosphorIconsRegular.receipt),
          label: Text(l10n.newBill),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(pendingOrdersCountProvider);
          ref.invalidate(openQuotesCountProvider);
          ref.invalidate(todaysBillCountProvider);
          ref.invalidate(totalDuesProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: WebBentoGrid(
            children: [
              WebStatTile(
                label: l10n.pendingOrders,
                value: pendingOrders.when(
                  data: (c) => '$c',
                  loading: () => '…',
                  error: (_, _) => '—',
                ),
                icon: PhosphorIconsRegular.shoppingCart,
                onTap: () => context.go('/sales/orders'),
              ),
              WebStatTile(
                label: l10n.quotes,
                value: quotes.when(
                  data: (c) => '$c',
                  loading: () => '…',
                  error: (_, _) => '—',
                ),
                icon: PhosphorIconsRegular.fileText,
                onTap: () => context.go('/sales/orders'),
              ),
              WebStatTile(
                label: l10n.todaysBills,
                value: todaysBills.when(
                  data: (c) => '$c',
                  loading: () => '…',
                  error: (_, _) => '—',
                ),
                icon: PhosphorIconsRegular.receipt,
                onTap: () => context.go('/sales/billing'),
              ),
              WebStatTile(
                label: l10n.dues,
                value: totalDues.when(
                  data: (d) => formatNpr(Paisa(d), showPaisa: false),
                  loading: () => '…',
                  error: (_, _) => '—',
                ),
                icon: PhosphorIconsRegular.wallet,
                onTap: () => context.go('/sales/customers'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
