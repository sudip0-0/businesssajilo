import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/money.dart';

/// Visual treatment for [BillSummary] — dense bar, card, or checkout block.
enum BillSummaryStyle { denseBar, card, checkout }

/// Shared bill totals: subtotal, discount editor, grand total.
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
    final discountError = (discount < 0 || discount > itemsTotal)
        ? l10n.discountExceedsItems
        : null;

    final accent = accentColor ?? BsColors.primary;
    final compact = style == BillSummaryStyle.denseBar;

    final discountField = TextFormField(
      controller: billDiscountController,
      decoration: InputDecoration(
        isDense: true,
        hintText: '0',
        errorText: discountError,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      keyboardType: TextInputType.number,
      onChanged: (_) => onDiscountChanged(),
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _summaryRow(context, l10n.subtotal, itemsTotal),
        SizedBox(height: compact ? 6 : 8),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.billDiscount,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            SizedBox(width: compact ? 96 : 120, child: discountField),
            if (style == BillSummaryStyle.card) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 72,
                child: Text(
                  discount > 0
                      ? '- ${formatNpr(Paisa(discount), showPaisa: false)}'
                      : '—',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ],
        ),
        Divider(height: compact ? 14 : 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.grandTotal,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              formatNpr(Paisa(grandTotal), showPaisa: false),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ],
        ),
      ],
    );

    if (style == BillSummaryStyle.checkout) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _summaryRow(context, l10n.subtotal, itemsTotal),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.billDiscount,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      l10n.discount,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: BsColors.outline),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 96, child: discountField),
            ],
          ),
          if (discount > 0) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '- ${formatNpr(Paisa(discount), showPaisa: false)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: BsColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(BsRadii.lg),
            ),
            child: Row(
              children: [
                Text(
                  l10n.grandTotal,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Text(
                  formatNpr(Paisa(grandTotal), showPaisa: false),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (style == BillSummaryStyle.card) {
      final bg = cardBackground ?? accent.withValues(alpha: 0.04);
      final border = cardBorderColor ?? accent.withValues(alpha: 0.12);
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
      padding: const EdgeInsets.fromLTRB(
        BsSpacing.lg,
        BsSpacing.sm,
        BsSpacing.lg,
        BsSpacing.sm,
      ),
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
