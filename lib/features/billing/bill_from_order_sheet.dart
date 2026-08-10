import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/ui/adaptive_sheet.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/submit_action.dart';
import '../../core/utils/money.dart';
import '../../data/repositories/bills_repository.dart';
import 'bill_payment_sheet.dart';
import 'create_bill_from_order.dart';
import 'invalidate_billing.dart';

class BillFromOrderSheet extends ConsumerStatefulWidget {
  const BillFromOrderSheet({
    super.key,
    required this.orderId,
    required this.customerId,
  });

  final String orderId;
  final String customerId;

  @override
  ConsumerState<BillFromOrderSheet> createState() => _BillFromOrderSheetState();
}

class _BillFromOrderSheetState extends ConsumerState<BillFromOrderSheet> {
  bool _loading = false;
  bool _draftLoading = true;
  bool _emptyDraft = false;
  List<BillLineInput> _lines = const [];

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    final draft = await loadBillFromOrderDraft(
      ref.read(billingRefProvider),
      widget.orderId,
    );
    if (!mounted) return;
    if (draft == null || draft.lines.isEmpty) {
      setState(() {
        _draftLoading = false;
        _emptyDraft = true;
      });
      return;
    }
    setState(() {
      _lines = List.of(draft.lines);
      _draftLoading = false;
    });
  }

  BillFromOrderDraft get _draft => BillFromOrderDraft(
    lines: _lines,
    itemsTotal: _lines.fold<int>(0, (sum, l) => sum + l.lineTotal),
  );

  void _updateLine(int index, BillLineInput line) {
    setState(() {
      _lines = [..._lines]..[index] = line;
    });
  }

  void _removeLine(int index) {
    setState(() {
      _lines = [..._lines]..removeAt(index);
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final draft = _draft;
    if (draft.lines.isEmpty) return;

    final payment = await showAdaptiveSheet<BillPaymentResult>(
      context: context,
      title: l10n.saveBill,
      child: BillPaymentSheet(grandTotal: draft.grandTotal),
    );
    if (payment == null) return;
    if (!mounted) return;

    setState(() => _loading = true);
    final ok = await runSubmitAction(
      context,
      action: () async {
        await saveBillFromOrder(
          ref.read(billingRefProvider),
          orderId: widget.orderId,
          customerId: widget.customerId,
          draft: draft,
          payment: payment,
        );
      },
      successMessage: l10n.billSaved,
    );
    if (ok && mounted) Navigator.pop(context, true);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_emptyDraft) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: ErrorState(message: l10n.noOrderItemsForBill),
      );
    }
    if (_draftLoading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final draft = _draft;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.makeThisBill,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _lines.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final line = _lines[index];
                return _EditableBillLineTile(
                  line: line,
                  onChanged: (next) => _updateLine(index, next),
                  onRemove: _lines.length > 1 ? () => _removeLine(index) : null,
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${l10n.grandTotal}: ${formatNpr(Paisa(draft.grandTotal), showPaisa: false)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _loading || draft.lines.isEmpty ? null : _save,
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.saveBill),
          ),
        ],
      ),
    );
  }
}

class _EditableBillLineTile extends StatelessWidget {
  const _EditableBillLineTile({
    required this.line,
    required this.onChanged,
    this.onRemove,
  });

  final BillLineInput line;
  final ValueChanged<BillLineInput> onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  line.nameSnapshot,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              if (onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: l10n.remove,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: '${line.qty}',
                  decoration: InputDecoration(labelText: l10n.qty),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) {
                    final qty = int.tryParse(value) ?? 1;
                    onChanged(billLineWithEdits(line, qty: qty < 1 ? 1 : qty));
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: formatNpr(
                    Paisa(line.rate),
                    showPaisa: false,
                  ).replaceAll(RegExp(r'[^\d]'), ''),
                  decoration: InputDecoration(labelText: l10n.rate),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) {
                    // Rate field is in whole NPR; convert to paisa.
                    final npr = int.tryParse(value) ?? 0;
                    onChanged(billLineWithEdits(line, rate: npr * 100));
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: formatNpr(
                    Paisa(line.discount),
                    showPaisa: false,
                  ).replaceAll(RegExp(r'[^\d]'), ''),
                  decoration: InputDecoration(labelText: l10n.discount),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) {
                    final npr = int.tryParse(value) ?? 0;
                    onChanged(billLineWithEdits(line, discount: npr * 100));
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              formatNpr(Paisa(line.lineTotal), showPaisa: false),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}
