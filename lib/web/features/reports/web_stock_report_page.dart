import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/money.dart';
import '../../../domain/models/stock_valuation_row.dart';
import '../../../features/reports/providers.dart';
import '../../../features/reports/report_export_actions.dart';
import '../../layout/web_bento_grid.dart';
import '../../theme/web_palette.dart';
import '../../theme/web_typography.dart';
import '../../ui/web_data_table.dart';
import '../../ui/web_empty_state.dart';
import '../../ui/web_stat_tile.dart';
import '../web_page_scaffold.dart';
import 'widgets/report_filter_bar.dart';

enum _StockStatusFilter { all, low, out, inStock }

class WebStockReportPage extends ConsumerStatefulWidget {
  const WebStockReportPage({super.key, this.initialStatus});

  /// Deep-link status: `low` / `out` / `in`.
  final String? initialStatus;

  @override
  ConsumerState<WebStockReportPage> createState() => _WebStockReportPageState();
}

class _WebStockReportPageState extends ConsumerState<WebStockReportPage> {
  int? _sortColumnIndex;
  bool _sortAscending = false;
  _StockStatusFilter _status = _StockStatusFilter.all;
  String _search = '';
  Timer? _debounce;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _status = switch (widget.initialStatus) {
      'low' => _StockStatusFilter.low,
      'out' => _StockStatusFilter.out,
      'in' => _StockStatusFilter.inStock,
      _ => _StockStatusFilter.all,
    };
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _search = value.trim().toLowerCase());
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stockAsync = ref.watch(stockValuationProvider(false));
    final lowOnly = _status == _StockStatusFilter.low;

    return WebPageScaffold(
      title: lowOnly ? l10n.lowStock : l10n.stockValuation,
      breadcrumbs: [
        l10n.reports,
        lowOnly ? l10n.lowStock : l10n.stockValuation,
      ],
      actions: [
        stockAsync.maybeWhen(
          data: (rows) => IconButton(
            tooltip: l10n.exportCsv,
            onPressed: () => exportStockValuationCsv(ref, context, rows),
            icon: const Icon(Icons.download_outlined),
          ),
          orElse: () => const SizedBox.shrink(),
        ),
      ],
      body: stockAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => WebEmptyState(
          icon: PhosphorIconsRegular.warningCircle,
          message: l10n.loadingFailed,
          actionLabel: l10n.tryAgain,
          onAction: () => ref.invalidate(stockValuationProvider(false)),
        ),
        data: (rows) => _StockBody(
          rows: rows,
          sortColumnIndex: _sortColumnIndex,
          sortAscending: _sortAscending,
          status: _status,
          search: _search,
          searchController: _searchController,
          onSearchChanged: _onSearchChanged,
          onStatusChanged: (s) => setState(() => _status = s),
          onSort: (column, asc) {
            setState(() {
              _sortColumnIndex = column;
              _sortAscending = asc;
            });
          },
        ),
      ),
    );
  }
}

class _StockBody extends StatelessWidget {
  const _StockBody({
    required this.rows,
    required this.sortColumnIndex,
    required this.sortAscending,
    required this.status,
    required this.search,
    required this.searchController,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onSort,
  });

  final List<StockValuationRow> rows;
  final int? sortColumnIndex;
  final bool sortAscending;
  final _StockStatusFilter status;
  final String search;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<_StockStatusFilter> onStatusChanged;
  final void Function(int column, bool ascending) onSort;

  bool _matchesStatus(StockValuationRow r) {
    return switch (status) {
      _StockStatusFilter.all => true,
      _StockStatusFilter.low => r.isLowStock,
      _StockStatusFilter.out => r.stockCached <= 0,
      _StockStatusFilter.inStock => r.stockCached > 0 && !r.isLowStock,
    };
  }

  List<StockValuationRow> get _filtered {
    var list = rows.where((r) {
      if (!_matchesStatus(r)) return false;
      if (search.isEmpty) return true;
      return r.name.toLowerCase().contains(search);
    }).toList();

    if (sortColumnIndex == null) {
      list.sort((a, b) => b.valuation.compareTo(a.valuation));
      return list;
    }
    list.sort((a, b) {
      final cmp = switch (sortColumnIndex) {
        0 => a.name.compareTo(b.name),
        1 => a.stockCached.compareTo(b.stockCached),
        2 => a.costPrice.compareTo(b.costPrice),
        3 => a.valuation.compareTo(b.valuation),
        4 => (a.isLowStock ? 1 : 0).compareTo(b.isLowStock ? 1 : 0),
        _ => 0,
      };
      return sortAscending ? cmp : -cmp;
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filtered = _filtered;
    final totalValuation = rows.fold<int>(0, (s, r) => s + r.valuation);
    final lowCount = rows.where((r) => r.isLowStock).length;
    final outCount = rows.where((r) => r.stockCached <= 0).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WebBentoGrid(
                  columns: 4,
                  children: [
                    WebStatTile(
                      label: l10n.totalValuation,
                      value: formatNpr(Paisa(totalValuation), showPaisa: false),
                      icon: PhosphorIconsRegular.coins,
                    ),
                    WebStatTile(
                      label: l10n.productsTracked,
                      value: '${rows.length}',
                      icon: PhosphorIconsRegular.package,
                    ),
                    WebStatTile(
                      label: l10n.lowStock,
                      value: '$lowCount',
                      icon: PhosphorIconsRegular.warning,
                      onTap: () => onStatusChanged(_StockStatusFilter.low),
                    ),
                    WebStatTile(
                      label: l10n.outOfStock,
                      value: '$outCount',
                      icon: PhosphorIconsRegular.xCircle,
                      onTap: () => onStatusChanged(_StockStatusFilter.out),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ReportFilterBar(
                  searchHint: l10n.searchProductsHint,
                  searchController: searchController,
                  onSearchChanged: onSearchChanged,
                  filters: [
                    ChoiceChip(
                      label: Text(l10n.allStock),
                      selected: status == _StockStatusFilter.all,
                      onSelected: (_) =>
                          onStatusChanged(_StockStatusFilter.all),
                    ),
                    ChoiceChip(
                      label: Text(l10n.stockFilterLow),
                      selected: status == _StockStatusFilter.low,
                      onSelected: (_) =>
                          onStatusChanged(_StockStatusFilter.low),
                    ),
                    ChoiceChip(
                      label: Text(l10n.stockFilterOut),
                      selected: status == _StockStatusFilter.out,
                      onSelected: (_) =>
                          onStatusChanged(_StockStatusFilter.out),
                    ),
                    ChoiceChip(
                      label: Text(l10n.stockFilterIn),
                      selected: status == _StockStatusFilter.inStock,
                      onSelected: (_) =>
                          onStatusChanged(_StockStatusFilter.inStock),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (filtered.isEmpty)
                  WebEmptyState(
                    icon: PhosphorIconsRegular.package,
                    message: l10n.noMatchingResults,
                  )
                else
                  SizedBox(
                    height: 420,
                    child: WebDataTable<StockValuationRow>(
                      columns: [
                        DataColumn(label: Text(l10n.products), onSort: onSort),
                        DataColumn(
                          label: Text(l10n.qty),
                          numeric: true,
                          onSort: onSort,
                        ),
                        DataColumn(
                          label: Text(l10n.cost),
                          numeric: true,
                          onSort: onSort,
                        ),
                        DataColumn(
                          label: Text(l10n.valuation),
                          numeric: true,
                          onSort: onSort,
                        ),
                        DataColumn(label: Text(l10n.status), onSort: onSort),
                      ],
                      items: filtered,
                      sortColumnIndex: sortColumnIndex,
                      sortAscending: sortAscending,
                      onSort: onSort,
                      idFor: (r) => r.productId,
                      onRowTap: (r) =>
                          context.go('/owner/inventory/${r.productId}'),
                      rowBuilder: (r, _) => DataRow(
                        cells: [
                          DataCell(Text(r.name)),
                          DataCell(
                            Text(
                              '${r.stockCached}',
                              style: WebTypography.mono(fontSize: 12.5),
                            ),
                          ),
                          DataCell(
                            Text(
                              formatNpr(Paisa(r.costPrice), showPaisa: false),
                              style: WebTypography.mono(fontSize: 12.5),
                            ),
                          ),
                          DataCell(
                            Text(
                              formatNpr(Paisa(r.valuation), showPaisa: false),
                              style: WebTypography.mono(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          DataCell(_StockStatusChip(row: r)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StockStatusChip extends StatelessWidget {
  const _StockStatusChip({required this.row});

  final StockValuationRow row;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (label, color) = row.stockCached <= 0
        ? (l10n.outOfStock, WebPalette.danger)
        : row.isLowStock
        ? (l10n.lowStock, WebPalette.warning)
        : (l10n.inStock, WebPalette.success);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
