import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/layout/adaptive_scaffold.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/money_text.dart';
import '../../core/utils/money.dart';
import '../customers/customer_detail_screen.dart';
import 'providers.dart';
import 'report_period.dart';
import 'report_period_picker.dart';

enum _ProfitTab { products, customers }

class ProfitAnalyticsScreen extends ConsumerStatefulWidget {
  const ProfitAnalyticsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<ProfitAnalyticsScreen> createState() =>
      _ProfitAnalyticsScreenState();
}

class _ProfitAnalyticsScreenState extends ConsumerState<ProfitAnalyticsScreen> {
  ReportPeriod _period = ReportPeriod.preset(ReportPeriodPreset.last30Days);
  _ProfitTab _currentTab = _ProfitTab.products;

  void _showCustomerTopProducts(
    BuildContext context,
    String customerId,
    String shopName,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _DrilldownSheet(
        id: customerId,
        title: shopName,
        subtitle: AppLocalizations.of(context).topProductsForCustomer,
        isCustomer: true,
        onViewProfile: () {
          Navigator.pop(ctx);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CustomerDetailScreen(customerId: customerId),
            ),
          );
        },
      ),
    );
  }

  void _showProductTopCustomers(
    BuildContext context,
    String productId,
    String productName,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _DrilldownSheet(
        id: productId,
        title: productName,
        subtitle: AppLocalizations.of(context).topCustomersForProduct,
        isCustomer: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profitSummaryAsync = ref.watch(profitSummaryProvider(_period));
    final profitableProductsAsync =
        ref.watch(topProfitableProductsProvider(_period));
    final profitableCustomersAsync =
        ref.watch(topProfitableCustomersProvider(_period));
    final isWide = isWideLayout(context);

    final body = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ReportPeriodPicker(
          value: _period,
          onChanged: (p) => setState(() => _period = p),
        ),
        const SizedBox(height: 16),
        // Profit Summary KPI Bento
        profitSummaryAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (_, _) => ErrorState(
            message: l10n.loadingFailed,
            onRetry: () => ref.invalidate(profitSummaryProvider(_period)),
          ),
          data: (summary) {
            return GridView.count(
              crossAxisCount: isWide ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: isWide ? 2.0 : 1.35,
              children: [
                _KpiCard(
                  label: l10n.grossProfit,
                  value: formatNpr(Paisa(summary.grossProfit), showPaisa: false),
                  icon: Icons.trending_up,
                  color: summary.grossProfit >= 0
                      ? BsColors.primary
                      : BsColors.danger,
                ),
                _KpiCard(
                  label: l10n.profitMargin,
                  value: '${summary.marginPct.toStringAsFixed(1)}%',
                  icon: Icons.pie_chart_outline,
                  color: Colors.teal,
                ),
                _KpiCard(
                  label: l10n.totalSales,
                  value: formatNpr(Paisa(summary.totalRevenue), showPaisa: false),
                  icon: Icons.payments_outlined,
                  color: Colors.indigo,
                ),
                _KpiCard(
                  label: l10n.totalCost,
                  value: formatNpr(Paisa(summary.totalCogs), showPaisa: false),
                  icon: Icons.shopping_bag_outlined,
                  color: Colors.amber.shade800,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        // Tab switcher
        Row(
          children: [
            ChoiceChip(
              label: Text(l10n.profitableProducts),
              selected: _currentTab == _ProfitTab.products,
              onSelected: (_) =>
                  setState(() => _currentTab = _ProfitTab.products),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: Text(l10n.profitableCustomers),
              selected: _currentTab == _ProfitTab.customers,
              onSelected: (_) =>
                  setState(() => _currentTab = _ProfitTab.customers),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_currentTab == _ProfitTab.products) ...[
          profitableProductsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => ErrorState(
              message: l10n.loadingFailed,
              onRetry: () =>
                  ref.invalidate(topProfitableProductsProvider(_period)),
            ),
            data: (rows) {
              if (rows.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: EmptyState(
                    icon: Icons.inventory_2_outlined,
                    message: l10n.noSalesInPeriod,
                  ),
                );
              }
              final maxProfit = rows.fold<int>(
                0,
                (max, r) => r.grossProfit > max ? r.grossProfit : max,
              );
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final p = rows[index];
                    final ratio =
                        maxProfit > 0 ? (p.grossProfit / maxProfit) : 0.0;
                    return InkWell(
                      onTap: () => _showProductTopCustomers(
                        context,
                        p.productId,
                        p.nameSnapshot,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 26,
                                  height: 26,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: index < 3
                                        ? BsColors.primary
                                            .withValues(alpha: 0.15)
                                        : Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: index < 3
                                          ? BsColors.primary
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.nameSnapshot,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${l10n.qtySold}: ${p.qtySold} · ${l10n.totalSales}: ${formatNpr(Paisa(p.revenue), showPaisa: false)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: BsColors.outline),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    MoneyText(
                                      Paisa(p.grossProfit),
                                      showPaisa: false,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: p.grossProfit >= 0
                                            ? BsColors.primary
                                            : BsColors.danger,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.teal.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${p.marginPct.toStringAsFixed(1)}% ${l10n.margin.toLowerCase()}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.teal.shade800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.chevron_right,
                                  size: 18,
                                  color: BsColors.outline,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: ratio.clamp(0.0, 1.0),
                                minHeight: 4,
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  index == 0
                                      ? BsColors.primary
                                      : BsColors.primary
                                          .withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ] else if (_currentTab == _ProfitTab.customers) ...[
          profitableCustomersAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => ErrorState(
              message: l10n.loadingFailed,
              onRetry: () =>
                  ref.invalidate(topProfitableCustomersProvider(_period)),
            ),
            data: (rows) {
              if (rows.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: EmptyState(
                    icon: Icons.people_outline,
                    message: l10n.noSalesInPeriod,
                  ),
                );
              }
              final maxProfit = rows.fold<int>(
                0,
                (max, r) => r.grossProfit > max ? r.grossProfit : max,
              );
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final c = rows[index];
                    final ratio =
                        maxProfit > 0 ? (c.grossProfit / maxProfit) : 0.0;
                    return InkWell(
                      onTap: () => _showCustomerTopProducts(
                        context,
                        c.customerId,
                        c.shopName,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 26,
                                  height: 26,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: index < 3
                                        ? Colors.teal.withValues(alpha: 0.15)
                                        : Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: index < 3
                                          ? Colors.teal
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c.shopName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${c.billCount} ${l10n.bills.toLowerCase()} · ${l10n.totalSales}: ${formatNpr(Paisa(c.revenue), showPaisa: false)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: BsColors.outline),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    MoneyText(
                                      Paisa(c.grossProfit),
                                      showPaisa: false,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: c.grossProfit >= 0
                                            ? Colors.teal
                                            : BsColors.danger,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.teal.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${c.marginPct.toStringAsFixed(1)}% ${l10n.margin.toLowerCase()}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.teal.shade800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.chevron_right,
                                  size: 18,
                                  color: BsColors.outline,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: ratio.clamp(0.0, 1.0),
                                minHeight: 4,
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  index == 0
                                      ? Colors.teal
                                      : Colors.teal.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ],
    );

    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profitAnalytics)),
      body: body,
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DrilldownSheet extends ConsumerWidget {
  const _DrilldownSheet({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.isCustomer,
    this.onViewProfile,
  });

  final String id;
  final String title;
  final String subtitle;
  final bool isCustomer;
  final VoidCallback? onViewProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final rowsAsync = ref.watch(
      isCustomer
          ? customerTopProductsProvider(id)
          : productTopCustomersProvider(id),
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.88,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: BsColors.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onViewProfile != null)
                    TextButton(
                      onPressed: onViewProfile,
                      child: Text(l10n.viewReport),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              rowsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (_, _) => ErrorState(
                  message: l10n.loadingFailed,
                  onRetry: () => ref.invalidate(
                    isCustomer
                        ? customerTopProductsProvider(id)
                        : productTopCustomersProvider(id),
                  ),
                ),
                data: (rows) {
                  if (rows.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: EmptyState(
                        icon: Icons.analytics_outlined,
                        message: l10n.noSalesInPeriod,
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
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
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${l10n.qtySold}: ${r.qtySold} · ${l10n.revenue}: ${formatNpr(Paisa(r.revenue), showPaisa: false)}',
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            MoneyText(
                              Paisa(r.grossProfit),
                              showPaisa: false,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: r.grossProfit >= 0
                                    ? BsColors.primary
                                    : BsColors.danger,
                              ),
                            ),
                            Text(
                              l10n.profit,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: BsColors.outline),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
