import 'package:flutter/material.dart';

import '../../domain/models/product.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../utils/stock_status.dart';

class StockBadge extends StatelessWidget {
  const StockBadge({
    super.key,
    required this.product,
    this.compact = false,
  });

  final Product product;

  /// Icon + quantity only; full status lives in the tooltip / semantics.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final level = stockLevelFor(product);
    // Each level has an icon so the state is not color-only; low stock uses a
    // darker amber for text contrast on the tinted background.
    final (tint, textColor, icon, label) = switch (level) {
      StockLevel.inStock => (
        scheme.successColor,
        scheme.successColor,
        Icons.check_circle_outline,
        l10n.inStock,
      ),
      StockLevel.lowStock => (
        BsColors.accent,
        dark ? BsColors.accentDark : BsColors.amberTextOnTint,
        Icons.warning_amber_outlined,
        l10n.lowStock,
      ),
      StockLevel.outOfStock => (
        scheme.dangerColor,
        scheme.dangerColor,
        Icons.cancel_outlined,
        l10n.outOfStock,
      ),
    };

    final fullLabel = '${product.stockCached} · $label';
    final display = compact ? '${product.stockCached}' : fullLabel;

    return Semantics(
      label: fullLabel,
      child: Tooltip(
        message: fullLabel,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 6 : 8,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: textColor),
              const SizedBox(width: 4),
              Text(
                display,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
