import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/config/pagination.dart';
import '../theme/web_palette.dart';
import '../theme/web_typography.dart';

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
              return WebPalette.navyWash;
            }
            if (states.contains(WidgetState.hovered)) {
              return WebPalette.paperDeep.withValues(alpha: 0.55);
            }
            return null;
          }),
          onSelectChanged: widget.onRowTap != null
              ? (_) => widget.onRowTap!(item)
              : built.onSelectChanged,
        ),
      );
    }

    final tableCard = DecoratedBox(
      decoration: BoxDecoration(
        color: WebPalette.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: WebPalette.hairline),
        boxShadow: WebPalette.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Keep a readable column floor so narrow panes scroll
            // horizontally instead of clipping cell content.
            const minTableWidth = 640.0;
            final maxW = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : minTableWidth;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: maxW < minTableWidth ? minTableWidth : maxW,
                ),
                child: SingleChildScrollView(
                  child: DataTable(
                    sortColumnIndex: widget.sortColumnIndex,
                    sortAscending: widget.sortAscending,
                    columns: widget.columns,
                    rows: rows,
                    headingRowHeight: 44,
                    dataRowMinHeight: rowHeight,
                    dataRowMaxHeight: rowHeight + 8,
                    columnSpacing: 24,
                    horizontalMargin: 20,
                    showCheckboxColumn: false,
                    dividerThickness: 1,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    final pagination =
        widget.onPageChanged != null && widget.totalItems != null
        ? _TablePagination(
            page: widget.page,
            totalItems: widget.totalItems!,
            onPageChanged: widget.onPageChanged!,
          )
        : null;

    // Only use Expanded when the parent gives a finite height. Nesting this
    // table in a ListView (or other unbounded parent) used to throw
    // "RenderFlex children have non-zero flex but incoming height
    // constraints are unbounded".
    return LayoutBuilder(
      builder: (context, constraints) {
        final bounded = constraints.hasBoundedHeight;
        return Column(
          mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (bounded) Expanded(child: tableCard) else tableCard,
            ?pagination,
          ],
        );
      },
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          Text(
            '$from–$to of $totalItems',
            style: WebTypography.mono(
              fontSize: 11.5,
              color: WebPalette.inkSoft,
            ),
          ),
          const Spacer(),
          _PageButton(
            icon: PhosphorIconsRegular.caretLeft,
            onPressed: page > 0 ? () => onPageChanged(page - 1) : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '${page + 1} / $totalPages',
              style: WebTypography.mono(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: WebPalette.ink,
              ),
            ),
          ),
          _PageButton(
            icon: PhosphorIconsRegular.caretRight,
            onPressed: page < totalPages - 1
                ? () => onPageChanged(page + 1)
                : null,
          ),
        ],
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({required this.icon, this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: enabled ? WebPalette.hairlineStrong : WebPalette.hairline,
          ),
          color: enabled ? WebPalette.cardBright : Colors.transparent,
        ),
        child: Icon(
          icon,
          size: 15,
          color: enabled ? WebPalette.ink : WebPalette.inkFaint,
        ),
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
        duration: 160.ms,
        decoration: BoxDecoration(
          color: widget.selected
              ? WebPalette.navyWash
              : _hovered
              ? WebPalette.paperDeep.withValues(alpha: 0.55)
              : null,
          border: const Border(
            bottom: BorderSide(color: WebPalette.hairline),
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
