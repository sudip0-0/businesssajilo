import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/ui/adaptive_sheet.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/submit_action.dart';
import '../../core/utils/bill_totals.dart';
import '../../core/utils/money.dart';
import '../../data/repositories/bills_repository.dart';
import 'bill_payment_sheet.dart';
import 'create_bill_from_order.dart';
import 'invalidate_billing.dart';

int? _parseBillQty(String? value) {
  final parsed = BigInt.tryParse(value?.trim() ?? '');
  if (parsed == null || parsed < BigInt.one) return null;
  if (parsed > BigInt.from(maxExactPaisa)) return null;
  return parsed.toInt();
}

class _BillLineRow {
  _BillLineRow(this.line)
    : qtyText = '${line.qty}',
      rateText = formatNpr(Paisa(line.rate), showSymbol: false),
      discountText = formatNpr(Paisa(line.discount), showSymbol: false);

  final Object slot = Object();
  BillLineInput line;
  String qtyText;
  String rateText;
  String discountText;
}

BillLineInput? _lineFromRaw(_BillLineRow row) {
  final qty = _parseBillQty(row.qtyText);
  final rate = parseNpr(row.rateText);
  final discount = parseNpr(row.discountText);
  if (qty == null ||
      rate == null ||
      rate.value < 0 ||
      discount == null ||
      discount.value < 0) {
    return null;
  }
  if (!isValidLineDiscount(
    qty: qty,
    ratePaisa: rate.value,
    discountPaisa: discount.value,
  )) {
    return null;
  }
  return billLineWithEdits(
    row.line,
    qty: qty,
    rate: rate.value,
    discount: discount.value,
  );
}

String? _qtyError(AppLocalizations l10n, String? qtyText, String rateText) {
  final qty = _parseBillQty(qtyText);
  if (qty == null) return l10n.invalidNumber;
  final rate = parseNpr(rateText);
  if (rate == null || rate.value < 0) return null;
  return tryLineGrossPaisa(qty: qty, ratePaisa: rate.value) == null
      ? l10n.invalidNumber
      : null;
}

String? _rateError(AppLocalizations l10n, String? rateText, String qtyText) {
  final parsed = parseNpr(rateText ?? '');
  if (parsed == null || parsed.value < 0) return l10n.invalidNumber;
  final qty = _parseBillQty(qtyText);
  if (qty == null) return null;
  return tryLineGrossPaisa(qty: qty, ratePaisa: parsed.value) == null
      ? l10n.invalidNumber
      : null;
}

String? _discountError(
  AppLocalizations l10n,
  String? discountText,
  String qtyText,
  String rateText,
) {
  final parsed = parseNpr(discountText ?? '');
  if (parsed == null || parsed.value < 0) return l10n.invalidNumber;
  final qty = _parseBillQty(qtyText);
  final rate = parseNpr(rateText);
  if (qty == null || rate == null || rate.value < 0) return null;
  final gross = tryLineGrossPaisa(qty: qty, ratePaisa: rate.value);
  if (gross == null) return l10n.invalidNumber;
  return parsed.value > gross ? l10n.discountExceedsLine : null;
}

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
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _draftLoading = true;
  bool _emptyDraft = false;
  Object? _draftError;
  final _rows = <_BillLineRow>[];

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    setState(() {
      _draftLoading = true;
      _draftError = null;
      _emptyDraft = false;
    });
    try {
      final draft = await loadBillFromOrderDraft(
        ref.read(billingRefProvider),
        widget.orderId,
      );
      if (!mounted) return;
      setState(() {
        _rows
          ..clear()
          ..addAll([
            for (final line in draft?.lines ?? const <BillLineInput>[])
              _BillLineRow(line),
          ]);
        _emptyDraft = _rows.isEmpty;
      });
    } catch (e) {
      if (mounted) setState(() => _draftError = e);
    } finally {
      if (mounted) setState(() => _draftLoading = false);
    }
  }

  BillFromOrderDraft? get _draft {
    final itemsTotal = tryItemsTotalPaisa(
      _rows.map((row) => row.line.lineTotal),
    );
    if (itemsTotal == null) return null;
    return BillFromOrderDraft(
      lines: [for (final row in _rows) row.line],
      itemsTotal: itemsTotal,
    );
  }

  List<BillLineInput>? get _resolvedLines {
    final lines = <BillLineInput>[];
    for (final row in _rows) {
      final line = _lineFromRaw(row);
      if (line == null) return null;
      lines.add(line);
    }
    return lines;
  }

  void _updateRaw(
    _BillLineRow row, {
    String? qty,
    String? rate,
    String? discount,
  }) {
    setState(() {
      if (qty != null) row.qtyText = qty;
      if (rate != null) row.rateText = rate;
      if (discount != null) row.discountText = discount;
      final resolved = _lineFromRaw(row);
      if (resolved != null) row.line = resolved;
    });
  }

  void _removeRow(_BillLineRow row) {
    setState(() => _rows.remove(row));
  }

  Future<void> _save() async {
    if (_loading || _draftLoading || _draftError != null) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final lines = _resolvedLines;
    if (lines == null || lines.isEmpty) return;
    final itemsTotal = tryItemsTotalPaisa(lines.map((line) => line.lineTotal));
    if (itemsTotal == null) return;
    final draft = BillFromOrderDraft(lines: lines, itemsTotal: itemsTotal);
    setState(() => _loading = true);
    try {
      await _confirmAndSave(draft);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmAndSave(BillFromOrderDraft draft) async {
    final l10n = AppLocalizations.of(context);
    if (draft.lines.isEmpty) return;

    final payment = await showAdaptiveSheet<BillPaymentResult>(
      context: context,
      title: l10n.saveBill,
      child: BillPaymentSheet(
        grandTotal: draft.grandTotal,
        initialCustomerId: widget.customerId,
      ),
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

    if (_draftError != null) {
      return ErrorState(message: l10n.loadingFailed, onRetry: _loadDraft);
    }
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

    return Form(
      key: _formKey,
      child: Padding(
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
                itemCount: _rows.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final row = _rows[index];
                  return _EditableBillLineTile(
                    key: ObjectKey(row.slot),
                    row: row,
                    onRawChanged: ({qty, rate, discount}) => _updateRaw(
                      row,
                      qty: qty,
                      rate: rate,
                      discount: discount,
                    ),
                    onRemove: _rows.length > 1 ? () => _removeRow(row) : null,
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${l10n.grandTotal}: ${draft == null ? l10n.invalidNumber : formatNpr(Paisa(draft.grandTotal))}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loading || _rows.isEmpty ? null : _save,
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
      ),
    );
  }
}

class _EditableBillLineTile extends StatelessWidget {
  const _EditableBillLineTile({
    super.key,
    required this.row,
    required this.onRawChanged,
    this.onRemove,
  });

  final _BillLineRow row;
  final void Function({String? qty, String? rate, String? discount})
  onRawChanged;
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
                  row.line.nameSnapshot,
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
                  initialValue: row.qtyText,
                  decoration: InputDecoration(labelText: l10n.qty),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) => _qtyError(l10n, value, row.rateText),
                  onChanged: (value) => onRawChanged(qty: value),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: row.rateText,
                  decoration: InputDecoration(labelText: l10n.rate),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) => _rateError(l10n, value, row.qtyText),
                  onChanged: (value) => onRawChanged(rate: value),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: row.discountText,
                  decoration: InputDecoration(labelText: l10n.discount),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) =>
                      _discountError(l10n, value, row.qtyText, row.rateText),
                  onChanged: (value) => onRawChanged(discount: value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              formatNpr(Paisa(row.line.lineTotal)),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}
