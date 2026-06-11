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
    final color = !colorBySign
        ? null
        : amount.isNegative
            ? BsColors.danger
            : BsColors.success;
    return Text(
      formatNpr(amount, showPaisa: showPaisa),
      style: base?.copyWith(color: color, fontWeight: FontWeight.w600),
    );
  }
}
