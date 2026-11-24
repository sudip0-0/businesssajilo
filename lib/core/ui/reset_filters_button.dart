import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Compact active-filter indicator with a one-tap reset action.
class ResetFiltersButton extends StatelessWidget {
  const ResetFiltersButton({
    super.key,
    required this.activeCount,
    required this.onReset,
  });

  final int activeCount;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    if (activeCount <= 0) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    return ActionChip(
      avatar: Icon(Icons.filter_alt_off_outlined, size: 16, color: cs.primary),
      label: Text(
        '${l10n.resetFilters} (${l10n.filtersActiveCount(activeCount)})',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: cs.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      onPressed: onReset,
      side: BorderSide(color: cs.primary.withValues(alpha: 0.35)),
      backgroundColor: cs.primary.withValues(alpha: 0.06),
      visualDensity: VisualDensity.compact,
    );
  }
}
