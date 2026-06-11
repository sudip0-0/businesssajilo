import 'package:flutter/material.dart';

import '../../domain/models/product.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../utils/stock_status.dart';

class StockBadge extends StatelessWidget {
  const StockBadge({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final level = stockLevelFor(product);
    final (color, label) = switch (level) {
      StockLevel.inStock => (BsColors.success, l10n.inStock),
      StockLevel.lowStock => (BsColors.accent, l10n.lowStock),
      StockLevel.outOfStock => (BsColors.danger, l10n.outOfStock),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${product.stockCached} · $label',
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
