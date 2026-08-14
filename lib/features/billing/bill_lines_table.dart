import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';

const _compactBillLinesBreakpoint = 600.0;
const _qtyColumnWidth = 40.0;
const _rateColumnWidth = 72.0;
const _amountColumnWidth = 80.0;

bool isCompactBillLinesWidth(double width) =>
    width < _compactBillLinesBreakpoint;

class BillLineView {
  const BillLineView({
    required this.name,
    required this.qty,
    required this.rate,
    required this.amount,
  });

  final String name;
  final String qty;
  final String rate;
  final String amount;
}

/// Product-first line items: stacked on phones, table on wider layouts.
class BillLinesTable extends StatelessWidget {
  const BillLinesTable({super.key, required this.l10n, required this.lines});

  final AppLocalizations l10n;
  final List<BillLineView> lines;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = isCompactBillLinesWidth(constraints.maxWidth);
        if (compact) {
          return Column(
            children: [
              for (var i = 0; i < lines.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: BillLineStackedRow(line: lines[i]),
                ),
              ],
            ],
          );
        }
        return Column(
          children: [
            ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: BillLinesHeader(l10n: l10n),
              ),
            ),
            for (var i = 0; i < lines.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: BillLineRow(line: lines[i]),
              ),
            ],
          ],
        );
      },
    );
  }
}

class BillLinesHeader extends StatelessWidget {
  const BillLinesHeader({super.key, required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w700,
    );
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.productName,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(
          width: _qtyColumnWidth,
          child: Text(l10n.qty, style: style, textAlign: TextAlign.center),
        ),
        SizedBox(
          width: _rateColumnWidth,
          child: Text(l10n.rate, style: style, textAlign: TextAlign.end),
        ),
        SizedBox(
          width: _amountColumnWidth,
          child: Text(l10n.amountRs, style: style, textAlign: TextAlign.end),
        ),
      ],
    );
  }
}

class BillLineRow extends StatelessWidget {
  const BillLineRow({super.key, required this.line});

  final BillLineView line;

  @override
  Widget build(BuildContext context) {
    final body = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            line.name,
            style: body,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(
          width: _qtyColumnWidth,
          child: Text(line.qty, style: body, textAlign: TextAlign.center),
        ),
        SizedBox(
          width: _rateColumnWidth,
          child: Text(line.rate, style: body, textAlign: TextAlign.end),
        ),
        SizedBox(
          width: _amountColumnWidth,
          child: Text(
            line.amount,
            style: body?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class BillLineStackedRow extends StatelessWidget {
  const BillLineStackedRow({super.key, required this.line});

  final BillLineView line;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          line.name,
          style: theme.bodyMedium,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                '${line.qty} × ${line.rate}',
                style: theme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            Text(
              line.amount,
              style: theme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
