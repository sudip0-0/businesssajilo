import 'package:flutter/material.dart';

import '../../domain/enums.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class BillStatusChip extends StatelessWidget {
  const BillStatusChip(this.status, {super.key});

  final BillStatus status;

  String _label(AppLocalizations l10n) => switch (status) {
    BillStatus.paid => l10n.paid,
    BillStatus.partial => l10n.partial,
    BillStatus.due => l10n.due,
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final (tint, textColor, icon) = switch (status) {
      BillStatus.paid => (
        scheme.successColor,
        scheme.successColor,
        Icons.check_circle_outline,
      ),
      BillStatus.partial => (
        BsColors.accent,
        dark ? BsColors.accentDark : BsColors.amberTextOnTint,
        Icons.timelapse,
      ),
      BillStatus.due => (
        scheme.dangerColor,
        scheme.dangerColor,
        Icons.error_outline,
      ),
    };
    final l10n = AppLocalizations.of(context);
    final label = _label(l10n);
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(BsRadii.full),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
