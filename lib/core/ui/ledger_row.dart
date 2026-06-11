import 'package:flutter/material.dart';
import '../layout/adaptive_scaffold.dart';
import '../theme/app_theme.dart';
import '../utils/bs_date.dart';
import '../utils/money.dart';
import 'money_text.dart';

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
    final dateWidth = isWideLayout(context) ? 200.0 : 120.0;

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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: dateWidth,
            child: Text(dateStr, style: theme.bodySmall),
          ),
          Expanded(
            child: Text(description, style: theme.bodyMedium),
          ),
          if (effectiveDebit.value > 0)
            SizedBox(
              width: 88,
              child: Text(
                // "+" prefix so debits aren't distinguished by color alone.
                '+${formatNpr(effectiveDebit, showPaisa: false)}',
                textAlign: TextAlign.end,
                style: theme.bodyMedium?.copyWith(color: BsColors.danger),
              ),
            )
          else
            const SizedBox(width: 88),
          if (effectiveCredit.value > 0)
            SizedBox(
              width: 88,
              child: Text(
                '-${formatNpr(effectiveCredit, showPaisa: false)}',
                textAlign: TextAlign.end,
                style: theme.bodyMedium?.copyWith(color: BsColors.success),
              ),
            )
          else
            const SizedBox(width: 88),
          SizedBox(
            width: 96,
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
        ],
      ),
    );
  }
}
