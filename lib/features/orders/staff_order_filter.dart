import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../domain/enums.dart';

/// Staff order list filter buckets.
enum StaffOrderFilter { needsAction, received, billed, all }

extension StaffOrderFilterX on StaffOrderFilter {
  String label(AppLocalizations l10n) => switch (this) {
    StaffOrderFilter.needsAction => l10n.needsAction,
    StaffOrderFilter.received => l10n.statusReceived,
    StaffOrderFilter.billed => l10n.statusBilled,
    StaffOrderFilter.all => l10n.allOrders,
  };

  /// Null means no status filter (all orders).
  List<OrderStatus>? get statuses => switch (this) {
    StaffOrderFilter.needsAction => [OrderStatus.placed],
    StaffOrderFilter.received => [OrderStatus.received],
    StaffOrderFilter.billed => [OrderStatus.billed],
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
