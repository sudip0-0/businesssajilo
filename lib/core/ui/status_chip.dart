import 'package:flutter/material.dart';

import '../../domain/enums.dart';
import '../l10n/app_localizations.dart';

/// Order status chip with the color mapping from Design.md.
class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});

  final OrderStatus status;

  static const _colors = <OrderStatus, Color>{
    OrderStatus.draft: Color(0xFF757575),
    OrderStatus.placed: Color(0xFF1565C0),
    OrderStatus.quoted: Color(0xFFF2A33C),
    OrderStatus.accepted: Color(0xFF0F6E5F),
    OrderStatus.rejected: Color(0xFFC62828),
    OrderStatus.confirmed: Color(0xFF0F6E5F),
    OrderStatus.packed: Color(0xFF6A1B9A),
    OrderStatus.dispatched: Color(0xFF6A1B9A),
    OrderStatus.billed: Color(0xFF2E7D32),
    OrderStatus.closed: Color(0xFF757575),
    OrderStatus.cancelled: Color(0xFFC62828),
  };

  String _label(AppLocalizations l10n) => switch (status) {
        OrderStatus.draft => '—',
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _label(l10n),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
