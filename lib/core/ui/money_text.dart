import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/money.dart';

/// Renders an NPR amount. Numbers are the hero (Design.md).
class MoneyText extends StatelessWidget {
  const MoneyText(
    this.amount, {
    super.key,
    this.style,
    this.colorBySign = false,
    this.showPaisa = true,
  });

  final Paisa amount;
  final TextStyle? style;

  /// Dues red, credits green — never by color alone, callers add icons/labels.
  final bool colorBySign;
  final bool showPaisa;

  @override
  Widget build(BuildContext context) {
    final base = style ?? Theme.of(context).textTheme.titleMedium;
    final scheme = Theme.of(context).colorScheme;
    final color = !colorBySign
        ? null
        : amount.isNegative
        ? scheme.dangerColor
        : scheme.successColor;
    final formatted = formatNpr(amount, showPaisa: showPaisa);
    // On web, money speaks in the mono ledger voice; mobile keeps the
    // platform default face.
    final effective = kIsWeb
        ? base?.copyWith(
            color: color,
            fontFamily: 'IBM Plex Mono',
            fontFamilyFallback: const ['Noto Sans Devanagari'],
            fontWeight: FontWeight.w500,
            letterSpacing: -0.2,
          )
        : base?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          );
    return Semantics(
      label: formatted,
      excludeSemantics: true,
      child: Text(formatted, style: effective),
    );
  }
}
