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
    OrderStatus.packed: Color(0xFF5B4B8A),
    OrderStatus.dispatched: Color(0xFF5B4B8A),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(BsRadii.full),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
