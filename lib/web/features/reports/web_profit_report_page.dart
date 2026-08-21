import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/money.dart';
import '../../../domain/models/profitable_customer_row.dart';
import '../../../domain/models/profitable_product_row.dart';
import '../../../features/reports/providers.dart';
import '../../../features/reports/report_period.dart';
import '../../layout/web_bento_grid.dart';
import '../../theme/web_palette.dart';
import '../../ui/web_empty_state.dart';
import '../../ui/web_stat_tile.dart';
import '../web_page_scaffold.dart';
import 'widgets/report_filter_bar.dart';
import 'widgets/report_period_picker.dart';

class WebProfitReportPage extends ConsumerStatefulWidget {
  const WebProfitReportPage({super.key, this.initialPeriod});

  final String? initialPeriod;

  @override
  ConsumerState<WebProfitReportPage> createState() =>
      _WebProfitReportPageState();
}

class _WebProfitReportPageState extends ConsumerState<WebProfitReportPage> {
  late ReportPeriod _period;

  @override
  void initState() {
    super.initState();
    _period = ReportPeriod.fromQuery(widget.initialPeriod);
  }

  void _showDrilldownDialog(
    BuildContext context, {
    required String id,
    required String title,
    required String subtitle,
    required bool isCustomer,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 500,
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subtitle,
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                  color: WebPalette.inkSoft,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Consumer(
                  builder: (context, ref, _) {
                    final async = ref.watch(
                      isCustomer
                          ? customerTopProductsProvider(id)
                          : productTopCustomersProvider(id),
                    );
                    return async.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (_, _) => Text(
                        AppLocalizations.of(context).loadingFailed,
                      ),
                      data: (rows) {
                        if (rows.isEmpty) {
                          return Center(
                            child: Text(
                              AppLocalizations.of(context).noSalesInPeriod,
                            ),
                          );
                        }
                        return ListView.separated(
                          itemCount: rows.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final r = rows[index];
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                radius: 12,
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                              title: Text(
                                r.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '${AppLocalizations.of(context).qtySold}: ${r.qtySold} · ${AppLocalizations.of(context).totalSales}: ${formatNpr(Paisa(r.revenue), showPaisa: false)}',
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    formatNpr(
                                      Paisa(r.grossProfit),
                                      showPaisa: false,
                                    ),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: r.grossProfit >= 0
                                          ? WebPalette.navy
                                          : WebPalette.danger,
                                    ),
                                  ),
                                  Text(
                                    AppLocalizations.of(context).profit,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(color: WebPalette.inkSoft),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context).close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final summaryAsync = ref.watch(profitSummaryProvider(_period));
    final productsAsync = ref.watch(topProfitableProductsProvider(_period));
    final customersAsync = ref.watch(topProfitableCustomersProvider(_period));

    return WebPageScaffold(
      title: l10n.profitAnalytics,
      breadcrumbs: [l10n.reports, l10n.profitAnalytics],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ReportFilterBar(
            leading: ReportPeriodPicker(
              value: _period,
              onChanged: (p) => setState(() => _period = p),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // KPI Bento Grid
                  summaryAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (_, _) => WebEmptyState(
                      icon: PhosphorIconsRegular.warningCircle,
                      message: l10n.loadingFailed,
                      actionLabel: l10n.tryAgain,
                      onAction: () =>
                          ref.invalidate(profitSummaryProvider(_period)),
                    ),
                    data: (summary) => WebBentoGrid(
                      columns: 4,
                      children: [
                        WebStatTile(
                          label: l10n.grossProfit,
                          value: formatNpr(
                            Paisa(summary.grossProfit),
                            showPaisa: false,
                          ),
                          icon: PhosphorIconsRegular.trendUp,
                        ),
                        WebStatTile(
                          label: l10n.profitMargin,
                          value: '${summary.marginPct.toStringAsFixed(1)}%',
                          icon: PhosphorIconsRegular.chartPie,
                        ),
                        WebStatTile(
                          label: l10n.totalSales,
                          value: formatNpr(
                            Paisa(summary.totalRevenue),
                            showPaisa: false,
                          ),
                          icon: PhosphorIconsRegular.currencyCircleDollar,
                        ),
                        WebStatTile(
                          label: l10n.totalCost,
                          value: formatNpr(
                            Paisa(summary.totalCogs),
                            showPaisa: false,
                          ),
                          icon: PhosphorIconsRegular.shoppingBag,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Two side-by-side tables
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 900;
                      final productsCard = _ProfitableProductsCard(
                        async: productsAsync,
                        onProductTap: (p) => _showDrilldownDialog(
                          context,
                          id: p.productId,
                          title: p.nameSnapshot,
                          subtitle: l10n.topCustomersForProduct,
                          isCustomer: false,
                        ),
                      );
                      final customersCard = _ProfitableCustomersCard(
                        async: customersAsync,
                        onCustomerTap: (c) => _showDrilldownDialog(
                          context,
                          id: c.customerId,
                          title: c.shopName,
                          subtitle: l10n.topProductsForCustomer,
                          isCustomer: true,
                        ),
                      );

                      if (wide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: productsCard),
                            const SizedBox(width: 20),
                            Expanded(child: customersCard),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          productsCard,
                          const SizedBox(height: 20),
                          customersCard,
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfitableProductsCard extends StatelessWidget {
  const _ProfitableProductsCard({
    required this.async,
    required this.onProductTap,
  });

  final AsyncValue<List<ProfitableProductRow>> async;
  final ValueChanged<ProfitableProductRow> onProductTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return WebBentoTile(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.profitableProducts,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                l10n.profit,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: WebPalette.inkSoft,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          async.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (_, _) => Text(l10n.loadingFailed),
            data: (rows) {
              if (rows.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: Text(l10n.noSalesInPeriod)),
                );
              }
              final maxProfit = rows.fold<int>(
                0,
                (max, r) => r.grossProfit > max ? r.grossProfit : max,
              );
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: rows.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final p = rows[index];
                  final ratio =
                      maxProfit > 0 ? (p.grossProfit / maxProfit) : 0.0;
                  return InkWell(
                    onTap: () => onProductTap(p),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${index + 1}.',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: WebPalette.inkSoft,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  p.nameSnapshot,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    formatNpr(
                                      Paisa(p.grossProfit),
                                      showPaisa: false,
                                    ),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: p.grossProfit >= 0
                                          ? WebPalette.navy
                                          : WebPalette.danger,
                                    ),
                                  ),
                                  Text(
                                    '${p.marginPct.toStringAsFixed(1)}% ${l10n.margin.toLowerCase()}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: WebPalette.inkSoft,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: ratio.clamp(0.0, 1.0),
                              minHeight: 4,
                              backgroundColor: WebPalette.paperDeep,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                WebPalette.navy,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProfitableCustomersCard extends StatelessWidget {
  const _ProfitableCustomersCard({
    required this.async,
    required this.onCustomerTap,
  });

  final AsyncValue<List<ProfitableCustomerRow>> async;
  final ValueChanged<ProfitableCustomerRow> onCustomerTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return WebBentoTile(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.profitableCustomers,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                l10n.profit,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: WebPalette.inkSoft,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          async.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (_, _) => Text(l10n.loadingFailed),
            data: (rows) {
              if (rows.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: Text(l10n.noSalesInPeriod)),
                );
              }
              final maxProfit = rows.fold<int>(
                0,
                (max, r) => r.grossProfit > max ? r.grossProfit : max,
              );
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: rows.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final c = rows[index];
                  final ratio =
                      maxProfit > 0 ? (c.grossProfit / maxProfit) : 0.0;
                  return InkWell(
                    onTap: () => onCustomerTap(c),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${index + 1}.',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: WebPalette.inkSoft,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  c.shopName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    formatNpr(
                                      Paisa(c.grossProfit),
                                      showPaisa: false,
                                    ),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: c.grossProfit >= 0
                                          ? WebPalette.navy
                                          : WebPalette.danger,
                                    ),
                                  ),
                                  Text(
                                    '${c.marginPct.toStringAsFixed(1)}% ${l10n.margin.toLowerCase()}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: WebPalette.inkSoft,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: ratio.clamp(0.0, 1.0),
                              minHeight: 4,
                              backgroundColor: WebPalette.paperDeep,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                WebPalette.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
