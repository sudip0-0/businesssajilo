import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/config/pagination.dart';
import '../../core/theme/app_theme.dart';

typedef WebDataRowBuilder<T> = DataRow Function(T item, int index);

/// Sortable, paginated data table for web back-office views.
class WebDataTable<T> extends StatefulWidget {
  const WebDataTable({
    super.key,
    required this.columns,
    required this.items,
    required this.rowBuilder,
    this.onRowTap,
    this.selectedId,
    this.idFor,
    this.loading = false,
    this.page = 0,
    this.totalItems,
    this.onPageChanged,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.onSort,
    this.compact = true,
  });

  final List<DataColumn> columns;
  final List<T> items;
  final WebDataRowBuilder<T> rowBuilder;
  final void Function(T item)? onRowTap;
  final String? selectedId;
  final String Function(T item)? idFor;
  final bool loading;
  final int page;
  final int? totalItems;
  final ValueChanged<int>? onPageChanged;
  final int? sortColumnIndex;
  final bool sortAscending;
  final void Function(int columnIndex, bool ascending)? onSort;
  final bool compact;

  @override
  State<WebDataTable<T>> createState() => _WebDataTableState<T>();
}

class _WebDataTableState<T> extends State<WebDataTable<T>> {
  @override
  Widget build(BuildContext context) {
    if (widget.loading && widget.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final rowHeight = widget.compact ? 40.0 : 48.0;

    final rows = <DataRow>[];
    for (var i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];
      final id = widget.idFor?.call(item);
      final selected = id != null && id == widget.selectedId;
      final built = widget.rowBuilder(item, i);

      rows.add(
        DataRow(
          cells: built.cells,
          selected: selected,
          color: WidgetStateProperty.resolveWith((states) {
            if (selected) {
              return BsColors.primary.withValues(alpha: 0.06);
            }
            if (states.contains(WidgetState.hovered)) {
              return BsColors.rowHover;
            }
            return null;
          }),
          onSelectChanged: widget.onRowTap != null
              ? (_) => widget.onRowTap!(item)
              : built.onSelectChanged,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(BsRadii.lg),
              border: Border.all(color: BsColors.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(BsRadii.lg),
              child: SingleChildScrollView(
                child: DataTable(
                  sortColumnIndex: widget.sortColumnIndex,
                  sortAscending: widget.sortAscending,
                  columns: widget.columns,
                  rows: rows,
                  headingRowHeight: 44,
                  dataRowMinHeight: rowHeight,
                  dataRowMaxHeight: rowHeight + 8,
                  showCheckboxColumn: false,
                  dividerThickness: 1,
                ),
              ),
            ),
          ),
        ),
        if (widget.onPageChanged != null && widget.totalItems != null)
          _TablePagination(
            page: widget.page,
            totalItems: widget.totalItems!,
            onPageChanged: widget.onPageChanged!,
          ),
      ],
    );
  }
}

class _TablePagination extends StatelessWidget {
  const _TablePagination({
    required this.page,
    required this.totalItems,
    required this.onPageChanged,
  });

  final int page;
  final int totalItems;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final totalPages = (totalItems / kListPageSize).ceil().clamp(1, 9999);
    final from = page * kListPageSize + 1;
    final to = ((page + 1) * kListPageSize).clamp(0, totalItems);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            '$from-$to of $totalItems',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Spacer(),
          IconButton(
            onPressed: page > 0 ? () => onPageChanged(page - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text('${page + 1} / $totalPages'),
          IconButton(
            onPressed: page < totalPages - 1
                ? () => onPageChanged(page + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

/// Hover-aware table row wrapper for list-based tables.
class WebHoverableRow extends StatefulWidget {
  const WebHoverableRow({
    super.key,
    required this.child,
    required this.onTap,
    this.selected = false,
  });

  final Widget child;
  final VoidCallback onTap;
  final bool selected;

  @override
  State<WebHoverableRow> createState() => _WebHoverableRowState();
}

class _WebHoverableRowState extends State<WebHoverableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: 200.ms,
        decoration: BoxDecoration(
          color: widget.selected
              ? BsColors.primary.withValues(alpha: 0.06)
              : _hovered
                  ? BsColors.rowHover
                  : null,
          border: const Border(
            bottom: BorderSide(color: BsColors.border),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(onTap: widget.onTap, child: widget.child),
        ),
      ),
    );
  }
}
