import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/money.dart';

/// Visual treatment for [BillSummary] — dense bar (mobile) vs card (web).
enum BillSummaryStyle { denseBar, card }

/// Shared bill totals: subtotal, discount editor, taxable, grand total.
class BillSummary extends StatelessWidget {
  const BillSummary({
    super.key,
    required this.itemsTotal,
    required this.billDiscountController,
    required this.grandTotal,
    required this.onDiscountChanged,
    this.style = BillSummaryStyle.denseBar,
    this.accentColor,
    this.cardBackground,
    this.cardBorderColor,
  });

  final int itemsTotal;
  final TextEditingController billDiscountController;
  final int grandTotal;
  final VoidCallback onDiscountChanged;
  final BillSummaryStyle style;

  /// Optional accent for card style (e.g. web navy). Defaults to [BsColors.primary].
  final Color? accentColor;
  final Color? cardBackground;
  final Color? cardBorderColor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final discount = parseNpr(billDiscountController.text)?.value ?? 0;
    final taxable = itemsTotal - discount;
    final discountError = (discount < 0 || discount > itemsTotal)
        ? l10n.discountExceedsItems
        : null;

    final accent = accentColor ?? BsColors.primary;

    final discountField = TextFormField(
      controller: billDiscountController,
      decoration: InputDecoration(
        labelText: l10n.billDiscount,
        isDense: true,
        errorText: discountError,
      ),
      keyboardType: TextInputType.number,
      onChanged: (_) => onDiscountChanged(),
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _summaryRow(context, l10n.subtotal, itemsTotal),
        const SizedBox(height: 8),
        if (style == BillSummaryStyle.card)
          Row(
            children: [
              Expanded(child: discountField),
              const SizedBox(width: 8),
              Text(
                discount > 0
                    ? '- ${formatNpr(Paisa(discount), showPaisa: false)}'
                    : '—',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          )
        else
          discountField,
        const SizedBox(height: 8),
        _summaryRow(context, l10n.taxableAmount, taxable),
        Divider(height: style == BillSummaryStyle.card ? 24 : 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.grandTotal,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              formatNpr(Paisa(grandTotal), showPaisa: false),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ],
        ),
      ],
    );

    if (style == BillSummaryStyle.card) {
      final bg =
          cardBackground ?? accent.withValues(alpha: 0.04);
      final border =
          cardBorderColor ?? accent.withValues(alpha: 0.12);
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(BsRadii.lg),
          border: Border.all(color: border),
        ),
        child: body,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: BsColors.primary.withValues(alpha: 0.04),
        border: const Border(top: BorderSide(color: BsColors.border)),
      ),
      padding: const EdgeInsets.all(BsSpacing.lg),
      child: body,
    );
  }

  Widget _summaryRow(BuildContext context, String label, int amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label), Text(formatNpr(Paisa(amount), showPaisa: false))],
    );
  }
}
