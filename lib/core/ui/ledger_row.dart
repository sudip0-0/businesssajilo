import 'package:flutter/material.dart';
import '../layout/adaptive_scaffold.dart';
import '../theme/app_theme.dart';
import '../utils/bs_date.dart';
import '../utils/money.dart';
import 'money_text.dart';

const _dateDescriptionGap = 12.0;
const _descriptionAmountGap = 16.0;
const _amountColumnGap = 12.0;
const _debitColumnWidth = 108.0;
const _creditColumnWidth = 108.0;
const _balanceColumnWidth = 108.0;

double ledgerDateColumnWidth(BuildContext context) =>
    isWideLayout(context) ? 200.0 : 100.0;

bool _isCompactLedger(BuildContext context) =>
    MediaQuery.sizeOf(context).width < 600;

/// Column headers aligned with [LedgerRow].
class LedgerTableHeader extends StatelessWidget {
  const LedgerTableHeader({
    super.key,
    required this.dateLabel,
    required this.descriptionLabel,
    required this.debitLabel,
    required this.creditLabel,
    required this.balanceLabel,
  });

  final String dateLabel;
  final String descriptionLabel;
  final String debitLabel;
  final String creditLabel;
  final String balanceLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme.labelSmall;
    final dateWidth = ledgerDateColumnWidth(context);
    final compact = _isCompactLedger(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: dateWidth,
            child: Text(dateLabel, style: theme),
          ),
          const SizedBox(width: _dateDescriptionGap),
          Expanded(child: Text(descriptionLabel, style: theme)),
          const SizedBox(width: _descriptionAmountGap),
          if (!compact) ...[
            SizedBox(
              width: _debitColumnWidth,
              child: Text(debitLabel, style: theme, textAlign: TextAlign.end),
            ),
            const SizedBox(width: _amountColumnGap),
            SizedBox(
              width: _creditColumnWidth,
              child: Text(creditLabel, style: theme, textAlign: TextAlign.end),
            ),
            const SizedBox(width: _amountColumnGap),
          ],
          SizedBox(
            width: _balanceColumnWidth,
            child: Text(balanceLabel, style: theme, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}

class LedgerRow extends StatelessWidget {
  const LedgerRow({
    super.key,
    required this.date,
    required this.description,
    required this.debit,
    required this.credit,
    required this.runningBalance,
  });

  final DateTime date;
  final String description;
  final Paisa debit;
  final Paisa credit;
  final Paisa runningBalance;

  @override
  Widget build(BuildContext context) {
    final dateStr = BsDate.both(date, locale: Localizations.localeOf(context));
    final theme = Theme.of(context).textTheme;
    final dateWidth = ledgerDateColumnWidth(context);
    final compact = _isCompactLedger(context);

    // Negative amounts flip columns: a negative debit (e.g. negative opening
    // balance) renders as a positive credit, and vice versa.
    final effectiveDebit = Paisa(
      (debit.value > 0 ? debit.value : 0) +
          (credit.value < 0 ? -credit.value : 0),
    );
    final effectiveCredit = Paisa(
      (credit.value > 0 ? credit.value : 0) +
          (debit.value < 0 ? -debit.value : 0),
    );
    final isCreditBalance = runningBalance.value < 0;
    final netChange = effectiveDebit.value - effectiveCredit.value;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: dateWidth,
            child: Text(dateStr, style: theme.bodySmall),
          ),
          const SizedBox(width: _dateDescriptionGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(description, style: theme.bodyMedium),
                if (compact && netChange != 0)
                  Text(
                    netChange > 0
                        ? '+${formatNpr(Paisa(netChange), showPaisa: false)}'
                        : '-${formatNpr(Paisa(-netChange), showPaisa: false)}',
                    style: theme.bodySmall?.copyWith(
                      color: netChange > 0 ? BsColors.danger : BsColors.success,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: _descriptionAmountGap),
          if (!compact) ...[
            SizedBox(
              width: _debitColumnWidth,
              child: effectiveDebit.value > 0
                  ? Text(
                      // "+" prefix so debits aren't distinguished by color alone.
                      '+${formatNpr(effectiveDebit, showPaisa: false)}',
                      textAlign: TextAlign.end,
                      style: theme.bodyMedium?.copyWith(color: BsColors.danger),
                    )
                  : null,
            ),
            const SizedBox(width: _amountColumnGap),
            SizedBox(
              width: _creditColumnWidth,
              child: effectiveCredit.value > 0
                  ? Text(
                      '-${formatNpr(effectiveCredit, showPaisa: false)}',
                      textAlign: TextAlign.end,
                      style: theme.bodyMedium?.copyWith(
                        color: BsColors.success,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: _amountColumnGap),
          ],
          SizedBox(
            width: _balanceColumnWidth,
            child: Align(
              alignment: Alignment.centerRight,
              child: MoneyText(
                runningBalance,
                style: isCreditBalance
                    ? theme.bodyMedium?.copyWith(
                        color: BsColors.primary,
                        fontWeight: FontWeight.w600,
                      )
                    : theme.bodyMedium,
                showPaisa: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
