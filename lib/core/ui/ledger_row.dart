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
    final dateStr = BsDate.both(date);
    final theme = Theme.of(context).textTheme;
    final dateWidth = isWideLayout(context) ? 200.0 : 120.0;

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
          if (debit.value > 0)
            SizedBox(
              width: 88,
              child: Text(
                formatNpr(debit, showPaisa: false),
                textAlign: TextAlign.end,
                style: theme.bodyMedium?.copyWith(color: BsColors.danger),
              ),
            )
          else
            const SizedBox(width: 88),
          if (credit.value > 0)
            SizedBox(
              width: 88,
              child: Text(
                formatNpr(credit, showPaisa: false),
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
              style: theme.bodyMedium,
              showPaisa: false,
            ),
          ),
        ],
      ),
    );
  }
}
