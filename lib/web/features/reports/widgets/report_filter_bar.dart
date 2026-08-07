import 'package:flutter/material.dart';

import '../../../theme/web_tokens.dart';
import '../../../ui/web_search_field.dart';

/// Responsive toolbar: period / leading on its own row, then search + filters.
class ReportFilterBar extends StatelessWidget {
  const ReportFilterBar({
    super.key,
    this.leading,
    this.searchHint,
    this.onSearchChanged,
    this.searchController,
    this.filters = const [],
    this.actions = const [],
  });

  final Widget? leading;
  final String? searchHint;
  final ValueChanged<String>? onSearchChanged;
  final TextEditingController? searchController;
  final List<Widget> filters;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final compact = context.isWebCompact;
    final search = searchHint != null && onSearchChanged != null
        ? WebSearchField(
            hint: searchHint!,
            onChanged: onSearchChanged,
            controller: searchController,
          )
        : null;

    final filterRow = filters.isEmpty && search == null && actions.isEmpty
        ? null
        : Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (search != null)
                SizedBox(
                  width: compact ? double.infinity : 280,
                  child: search,
                ),
              ...filters,
              ...actions,
            ],
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ?leading,
        if (filterRow != null) ...[
          SizedBox(height: leading != null ? 12 : 0),
          filterRow,
        ],
      ],
    );
  }
}
