import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/qty_stepper.dart';
import '../../core/utils/money.dart';
import '../inventory/product_image.dart';
import 'bill_draft_line.dart';

/// Mobile bill line editor row.
class BillFormLineEditor extends StatefulWidget {
  const BillFormLineEditor({
    super.key,
    required this.line,
    required this.onChanged,
    required this.onRemove,
    this.initiallyExpanded = false,
  });

  final BillDraftLine line;
  final VoidCallback onChanged;
  final VoidCallback onRemove;
  final bool initiallyExpanded;

  @override
  State<BillFormLineEditor> createState() => _BillFormLineEditorState();
}

class _BillFormLineEditorState extends State<BillFormLineEditor> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final line = widget.line;
    final oversell = line.qty > line.product.stockCached;
    final rateLabel = formatNpr(Paisa(line.rate), showPaisa: false);

    return Padding(
      padding: const EdgeInsets.only(bottom: BsSpacing.sm),
      child: Material(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BsRadii.xl),
          side: const BorderSide(color: BsColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProductImage(storagePath: line.product.imageUrl, size: 48),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          line.product.name,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$rateLabel · ${l10n.availableStock} ${line.product.stockCached}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: oversell
                                    ? BsColors.danger
                                    : BsColors.outline,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                    ),
                    tooltip: l10n.edit,
                    onPressed: () => setState(() => _expanded = !_expanded),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: BsColors.danger,
                    ),
                    tooltip: l10n.remove,
                    onPressed: widget.onRemove,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  QtyStepper(
                    compact: true,
                    value: line.qty,
                    min: 1,
                    onChanged: (v) {
                      line.setQty(v);
                      widget.onChanged();
                    },
                  ),
                  const Spacer(),
                  Text(
                    formatNpr(Paisa(line.lineTotal), showPaisa: false),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
              if (line.discount > 0 && !_expanded)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${l10n.discount} -${formatNpr(Paisa(line.discount), showPaisa: false)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (_expanded) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: formatNpr(
                          Paisa(line.rate),
                          showSymbol: false,
                          showPaisa: false,
                        ),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          isDense: true,
                          labelText: '${l10n.rate} (रू)',
                        ),
                        onChanged: (v) {
                          line.rate = parseNpr(v)?.value ?? line.rate;
                          widget.onChanged();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: line.discount == 0
                            ? ''
                            : formatNpr(
                                Paisa(line.discount),
                                showSymbol: false,
                                showPaisa: false,
                              ),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          isDense: true,
                          labelText: '${l10n.lineDiscount} (रू)',
                          errorText: line.discountValid
                              ? null
                              : l10n.discountExceedsLine,
                        ),
                        onChanged: (v) {
                          line.discount = parseNpr(v)?.value ?? 0;
                          widget.onChanged();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${l10n.lineTotal}: ${formatNpr(Paisa(line.lineTotal), showPaisa: false)}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
