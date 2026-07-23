import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/testing/integration_keys.dart';
import '../../../core/utils/money.dart';
import '../../../features/billing/bill_draft_line.dart';
import '../../theme/web_palette.dart';

/// Table header for bill line items on web.
class WebBillItemsTableHeader extends StatelessWidget {
  const WebBillItemsTableHeader({super.key, required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: WebPalette.inkSoft,
      fontWeight: FontWeight.w600,
    );

    return Row(
      children: [
        SizedBox(width: 36, child: Text(l10n.sn, style: style)),
        Expanded(flex: 3, child: Text(l10n.productName, style: style)),
        SizedBox(width: 72, child: Text(l10n.qty, style: style)),
        SizedBox(width: 56, child: Text(l10n.unit, style: style)),
        SizedBox(width: 96, child: Text(l10n.rateRs, style: style)),
        SizedBox(width: 96, child: Text(l10n.amountRs, style: style)),
        const SizedBox(width: 40),
      ],
    );
  }
}

/// Single editable bill line row on web.
class WebBillItemRow extends StatelessWidget {
  const WebBillItemRow({
    super.key,
    required this.index,
    required this.line,
    required this.l10n,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final BillDraftLine line;
  final AppLocalizations l10n;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: WebPalette.hairline.withValues(alpha: 0.6)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 36, child: Text('${index + 1}')),
          Expanded(
            flex: 3,
            child: Text(
              line.product.name,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          SizedBox(
            width: 72,
            child: TextFormField(
              initialValue: '${line.qty}',
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
              onChanged: (v) {
                line.setQty(int.tryParse(v) ?? line.qty);
                onChanged();
              },
            ),
          ),
          SizedBox(width: 56, child: Text(line.product.unit)),
          SizedBox(
            width: 96,
            child: TextFormField(
              initialValue: formatNpr(
                Paisa(line.rate),
                showSymbol: false,
                showPaisa: false,
              ),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
              onChanged: (v) {
                line.rate = parseNpr(v)?.value ?? line.rate;
                onChanged();
              },
            ),
          ),
          SizedBox(
            width: 96,
            child: Text(
              formatNpr(Paisa(line.lineTotal), showPaisa: false),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            tooltip: l10n.remove,
            icon: const Icon(
              PhosphorIconsRegular.trash,
              color: WebPalette.danger,
            ),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

/// Bill line items table with header, rows, and add-product affordance.
class WebBillFormLineTable extends StatelessWidget {
  const WebBillFormLineTable({
    super.key,
    required this.l10n,
    required this.lines,
    required this.onLineChanged,
    required this.onRemoveLine,
    required this.onFocusProductSearch,
  });

  final AppLocalizations l10n;
  final List<BillDraftLine> lines;
  final VoidCallback onLineChanged;
  final ValueChanged<int> onRemoveLine;
  final VoidCallback onFocusProductSearch;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              l10n.billLines,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Spacer(),
            TextButton.icon(
              key: IntegrationKeys.billFormAddProduct,
              onPressed: onFocusProductSearch,
              icon: const Icon(PhosphorIconsRegular.plus, size: 16),
              label: Text(l10n.addProduct),
            ),
          ],
        ),
        const SizedBox(height: 12),
        WebBillItemsTableHeader(l10n: l10n),
        const SizedBox(height: 8),
        if (lines.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              l10n.noBillLines,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: WebPalette.inkSoft),
            ),
          )
        else
          for (var i = 0; i < lines.length; i++)
            WebBillItemRow(
              index: i,
              line: lines[i],
              l10n: l10n,
              onChanged: onLineChanged,
              onRemove: () => onRemoveLine(i),
            ),
      ],
    );
  }
}
