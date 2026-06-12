import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/config/pagination.dart';

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

  @override
  State<WebDataTable<T>> createState() => _WebDataTableState<T>();
}

class _WebDataTableState<T> extends State<WebDataTable<T>> {
  @override
  Widget build(BuildContext context) {
    if (widget.loading && widget.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

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
              return Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.08);
            }
            if (states.contains(WidgetState.hovered)) {
              return Theme.of(context).colorScheme.surfaceContainerLow;
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
          child: SingleChildScrollView(
            child: DataTable(
              sortColumnIndex: widget.sortColumnIndex,
              sortAscending: widget.sortAscending,
              columns: widget.columns,
              rows: rows,
              headingRowHeight: 44,
              dataRowMinHeight: 48,
              dataRowMaxHeight: 56,
              showCheckboxColumn: false,
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
          Text('$from–$to of $totalItems'),
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
    final scheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: 200.ms,
        decoration: BoxDecoration(
          color: widget.selected
              ? scheme.primary.withValues(alpha: 0.08)
              : _hovered
                  ? scheme.surfaceContainerLow
                  : null,
          border: Border(
            bottom: BorderSide(
              color: scheme.outline.withValues(alpha: 0.12),
            ),
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
