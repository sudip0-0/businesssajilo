import 'package:flutter/material.dart';

import '../../domain/enums.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// Order status chip with soft-fill badges per Design.md.
class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});

  final OrderStatus status;

  static const _colors = <OrderStatus, Color>{
    OrderStatus.draft: BsColors.outline,
    OrderStatus.placed: BsColors.info,
    OrderStatus.quoted: BsColors.accent,
    OrderStatus.accepted: BsColors.primary,
    OrderStatus.rejected: BsColors.danger,
    OrderStatus.confirmed: BsColors.primary,
    OrderStatus.packed: BsColors.fulfillment,
    OrderStatus.dispatched: BsColors.fulfillment,
    OrderStatus.billed: BsColors.secondary,
    OrderStatus.closed: BsColors.outline,
    OrderStatus.cancelled: BsColors.danger,
  };

  String _label(AppLocalizations l10n) => switch (status) {
    OrderStatus.draft => '-',
    OrderStatus.placed => l10n.statusPlaced,
    OrderStatus.quoted => l10n.statusQuoted,
    OrderStatus.accepted => l10n.statusAccepted,
    OrderStatus.rejected => l10n.statusRejected,
    OrderStatus.confirmed => l10n.statusConfirmed,
    OrderStatus.packed => l10n.statusPacked,
    OrderStatus.dispatched => l10n.statusDispatched,
    OrderStatus.billed => l10n.statusBilled,
    OrderStatus.closed => l10n.statusClosed,
    OrderStatus.cancelled => l10n.statusCancelled,
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[status]!;
    final l10n = AppLocalizations.of(context);
    final label = _label(l10n);
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.55,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
