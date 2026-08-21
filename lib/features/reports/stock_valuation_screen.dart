import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/layout/adaptive_scaffold.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/list_skeleton.dart';
import '../../core/ui/money_text.dart';
import '../../core/utils/money.dart';
import 'providers.dart';
import 'report_export_actions.dart';

enum _StockFilter { all, low, out, inStock }

class StockValuationScreen extends ConsumerStatefulWidget {
  const StockValuationScreen({
    super.key,
    this.lowStockOnly = false,
    this.embedded = false,
  });

  final bool lowStockOnly;
  final bool embedded;

  @override
  ConsumerState<StockValuationScreen> createState() =>
      _StockValuationScreenState();
}

class _StockValuationScreenState extends ConsumerState<StockValuationScreen> {
  _StockFilter _filter = _StockFilter.all;
  String _search = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.lowStockOnly) {
      _filter = _StockFilter.low;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rowsAsync = ref.watch(stockValuationProvider(false));
    final isWide = isWideLayout(context);

    final body = rowsAsync.when(
      loading: () => const ListSkeleton(),
      error: (e, _) => ErrorState(
        message: l10n.loadingFailed,
        onRetry: () => ref.invalidate(stockValuationProvider(false)),
      ),
      data: (rows) {
        final totalValuation = rows.fold<int>(
          0,
          (sum, r) => sum + r.valuation,
        );
        final totalUnits = rows.fold<int>(
          0,
          (sum, r) => sum + (r.stockCached > 0 ? r.stockCached : 0),
        );
        final lowStockCount = rows.where((r) => r.isLowStock).length;
        final outOfStockCount = rows.where((r) => r.stockCached <= 0).length;

        final filtered = rows.where((r) {
          if (_filter == _StockFilter.low && !r.isLowStock) return false;
          if (_filter == _StockFilter.out && r.stockCached > 0) return false;
          if (_filter == _StockFilter.inStock && r.stockCached <= 0) return false;
          if (_search.isNotEmpty &&
              !r.name.toLowerCase().contains(_search.toLowerCase())) {
            return false;
          }
          return true;
        }).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.embedded)
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: l10n.exportCsv,
                  onPressed: rows.isEmpty
                      ? null
                      : () => exportStockValuationCsv(ref, context, filtered),
                  icon: const Icon(Icons.download_outlined),
                ),
              ),
            // KPI Summary Bento
            GridView.count(
              crossAxisCount: isWide ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: isWide ? 2.0 : 1.35,
              children: [
                _KpiCard(
                  label: l10n.totalValuation,
                  value: formatNpr(Paisa(totalValuation), showPaisa: false),
                  icon: Icons.account_balance_outlined,
                  color: BsColors.primary,
                ),
                _KpiCard(
                  label: l10n.totalUnitsInStock,
                  value: '$totalUnits',
                  icon: Icons.inventory_2_outlined,
                  color: Colors.indigo,
                ),
                _KpiCard(
                  label: l10n.lowStock,
                  value: '$lowStockCount',
                  icon: Icons.warning_amber_rounded,
                  color: Colors.amber.shade800,
                ),
                _KpiCard(
                  label: l10n.outOfStockCount,
                  value: '$outOfStockCount',
                  icon: Icons.remove_circle_outline,
                  color: BsColors.danger,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Search and filter chips
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, size: 20),
                hintText: l10n.searchProductsHint,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _search = '');
                        },
                      )
                    : null,
              ),
              onChanged: (val) => setState(() => _search = val.trim()),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text(l10n.allStock),
                    selected: _filter == _StockFilter.all,
                    onSelected: (_) => setState(() => _filter = _StockFilter.all),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text('${l10n.lowStock} ($lowStockCount)'),
                    selected: _filter == _StockFilter.low,
                    onSelected: (_) => setState(() => _filter = _StockFilter.low),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text('${l10n.outOfStockCount} ($outOfStockCount)'),
                    selected: _filter == _StockFilter.out,
                    onSelected: (_) => setState(() => _filter = _StockFilter.out),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(l10n.stockFilterIn),
                    selected: _filter == _StockFilter.inStock,
                    onSelected: (_) =>
                        setState(() => _filter = _StockFilter.inStock),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: EmptyState(
                  icon: Icons.inventory_2_outlined,
                  message: l10n.emptyNoProducts,
                ),
              )
            else ...[
              for (final r in filtered) ...[
                Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    title: Text(
                      r.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Row(
                      children: [
                        Text('${l10n.stock}: ${r.stockCached}'),
                        if (r.costPrice > 0) ...[
                          const Text(' · '),
                          Text(
                            '${l10n.costPrice}: ${formatNpr(Paisa(r.costPrice), showPaisa: false)}',
                          ),
                        ],
                        if (r.isLowStock) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              l10n.lowStock,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ),
                        ] else if (r.stockCached <= 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              l10n.outOfStock,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade900,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        MoneyText(
                          Paisa(r.valuation),
                          showPaisa: false,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          l10n.totalValuation,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: BsColors.outline),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ],
        );
      },
    );

    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lowStockOnly ? l10n.lowStock : l10n.stockValuation),
        actions: [
          IconButton(
            tooltip: l10n.exportCsv,
            onPressed: () {
              final rows = rowsAsync.value ?? const [];
              if (rows.isNotEmpty) {
                exportStockValuationCsv(ref, context, rows);
              }
            },
            icon: const Icon(Icons.download_outlined),
          ),
        ],
      ),
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
