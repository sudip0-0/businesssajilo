import 'package:flutter/material.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/qty_stepper.dart';
import '../../../core/utils/money.dart';
import 'bill_draft_line.dart';

/// Mobile bill line editor row.
class BillFormLineEditor extends StatefulWidget {
  const BillFormLineEditor({
    super.key,
    required this.line,
    required this.onChanged,
    required this.onRemove,
  });

  final BillDraftLine line;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  State<BillFormLineEditor> createState() => _BillFormLineEditorState();
}

class _BillFormLineEditorState extends State<BillFormLineEditor> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final line = widget.line;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BsSpacing.lg,
        vertical: BsSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  line.product.name,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              IconButton(
                icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                tooltip: l10n.edit,
                onPressed: () => setState(() => _expanded = !_expanded),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: l10n.remove,
                onPressed: widget.onRemove,
              ),
            ],
          ),
          Row(
            children: [
              QtyStepper(
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
          if (_expanded) ...[
            const SizedBox(height: 8),
            Text(l10n.rate),
            TextFormField(
              initialValue: formatNpr(
                Paisa(line.rate),
                showSymbol: false,
                showPaisa: false,
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) {
                line.rate = parseNpr(v)?.value ?? line.rate;
                widget.onChanged();
              },
            ),
            const SizedBox(height: 4),
            Text(l10n.lineDiscount),
            TextFormField(
              initialValue: line.discount == 0
                  ? ''
                  : formatNpr(
                      Paisa(line.discount),
                      showSymbol: false,
                      showPaisa: false,
                    ),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                errorText: line.discountValid ? null : l10n.discountExceedsLine,
              ),
              onChanged: (v) {
                line.discount = parseNpr(v)?.value ?? 0;
                widget.onChanged();
              },
            ),
          ],
        ],
      ),
    );
  }
}
