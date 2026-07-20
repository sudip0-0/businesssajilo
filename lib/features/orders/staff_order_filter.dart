import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../domain/enums.dart';

/// Staff order list filter buckets.
enum StaffOrderFilter { needsAction, inProgress, completed, all }

extension StaffOrderFilterX on StaffOrderFilter {
  String label(AppLocalizations l10n) => switch (this) {
    StaffOrderFilter.needsAction => l10n.needsAction,
    StaffOrderFilter.inProgress => l10n.inProgress,
    StaffOrderFilter.completed => l10n.completed,
    StaffOrderFilter.all => l10n.allOrders,
  };

  /// Null means no status filter (all orders).
  List<OrderStatus>? get statuses => switch (this) {
    StaffOrderFilter.needsAction => [
      OrderStatus.placed,
      OrderStatus.quoted,
      OrderStatus.accepted,
    ],
    StaffOrderFilter.inProgress => [
      OrderStatus.confirmed,
      OrderStatus.packed,
      OrderStatus.dispatched,
    ],
    StaffOrderFilter.completed => [
      OrderStatus.billed,
      OrderStatus.closed,
      OrderStatus.rejected,
      OrderStatus.cancelled,
    ],
    StaffOrderFilter.all => null,
  };
}

class StaffOrderFilterBar extends StatelessWidget {
  const StaffOrderFilterBar({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final StaffOrderFilter value;
  final ValueChanged<StaffOrderFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Intrinsic height only — avoid scroll views that can confuse parent
    // Columns that also use Expanded (owner/sales web order list).
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final filter in StaffOrderFilter.values)
            FilterChip(
              label: Text(filter.label(l10n)),
              selected: value == filter,
              onSelected: (_) => onChanged(filter),
            ),
        ],
      ),
    );
  }
}
