import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/layout/adaptive_scaffold.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/list_skeleton.dart';
import '../../core/ui/money_text.dart';
import '../../core/utils/money.dart';
import '../../domain/models/stock_valuation_row.dart';
import 'providers.dart';

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
  int? _sortColumnIndex;
  bool _sortAscending = true;
  List<StockValuationRow> _sorted = [];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rowsAsync =
        ref.watch(stockValuationProvider(widget.lowStockOnly));

    final body = rowsAsync.when(
        loading: () => const ListSkeleton(),
        error: (e, _) => ErrorState(
          message: l10n.loadingFailed,
          onRetry: () =>
              ref.invalidate(stockValuationProvider(widget.lowStockOnly)),
        ),
        data: (rows) {
          _sorted = List<StockValuationRow>.from(rows);
          _applySort();
          final total = rows.fold<int>(0, (sum, r) => sum + r.valuation);
          if (rows.isEmpty) {
            return EmptyState(
              icon: Icons.inventory_2_outlined,
              message: l10n.emptyNoProducts,
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(l10n.totalValuation,
                  style: Theme.of(context).textTheme.titleMedium),
              MoneyText(
                Paisa(total),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              if (isWideLayout(context))
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    sortColumnIndex: _sortColumnIndex,
                    sortAscending: _sortAscending,
                    columns: [
                      DataColumn(
                        label: Text(l10n.products),
                        onSort: (_, asc) => _onSort(0, asc),
                      ),
                      DataColumn(
                        label: Text(l10n.stock),
                        numeric: true,
                        onSort: (_, asc) => _onSort(1, asc),
                      ),
                      DataColumn(
                        label: Text(l10n.costPrice),
                        numeric: true,
                        onSort: (_, asc) => _onSort(2, asc),
                      ),
                      DataColumn(
                        label: Text(l10n.totalValuation),
                        numeric: true,
                        onSort: (_, asc) => _onSort(3, asc),
                      ),
                    ],
                    rows: _sorted
                        .map(
                          (r) => DataRow(cells: [
                            DataCell(Text(r.name)),
                            DataCell(Text('${r.stockCached}')),
                            DataCell(Text(
                              formatNpr(Paisa(r.costPrice), showPaisa: false),
                            )),
                            DataCell(Text(
                              formatNpr(Paisa(r.valuation), showPaisa: false),
                            )),
                          ]),
                        )
                        .toList(),
                  ),
                )
              else
                ..._sorted.map(
                  (r) => ListTile(
                    title: Text(r.name),
                    subtitle: Text('${l10n.stock}: ${r.stockCached}'),
                    trailing: MoneyText(Paisa(r.valuation), showPaisa: false),
                  ),
                ),
            ],
          );
        },
    );

    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.lowStockOnly ? l10n.lowStock : l10n.stockValuation,
        ),
      ),
      body: body,
    );
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _applySort();
    });
  }

  void _applySort() {
    if (_sortColumnIndex == null) return;
    _sorted.sort((a, b) {
      final cmp = switch (_sortColumnIndex) {
        0 => a.name.compareTo(b.name),
        1 => a.stockCached.compareTo(b.stockCached),
        2 => a.costPrice.compareTo(b.costPrice),
        3 => a.valuation.compareTo(b.valuation),
        _ => 0,
      };
      return _sortAscending ? cmp : -cmp;
    });
  }
}
