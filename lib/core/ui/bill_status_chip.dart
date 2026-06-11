import 'package:flutter/material.dart';

import '../../domain/enums.dart';
import '../l10n/app_localizations.dart';

class BillStatusChip extends StatelessWidget {
  const BillStatusChip(this.status, {super.key});

  final BillStatus status;

  static const _colors = <BillStatus, Color>{
    BillStatus.paid: Color(0xFF2E7D32),
    BillStatus.partial: Color(0xFFF2A33C),
    BillStatus.due: Color(0xFFC62828),
  };

  String _label(AppLocalizations l10n) => switch (status) {
        BillStatus.paid => l10n.paid,
        BillStatus.partial => l10n.partial,
        BillStatus.due => l10n.due,
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
