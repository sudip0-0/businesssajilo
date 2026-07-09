import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/bill_totals.dart';
import '../../core/utils/money.dart';
import '../../data/repositories/credit_notes_repository.dart';
import '../../domain/models/bill.dart';
import '../../domain/models/credit_note.dart';
import '../auth/providers/auth_provider.dart';
import '../customers/providers.dart';
import 'credit_note_providers.dart';
import 'invoice_export_actions.dart';
import 'providers.dart';

class CreditNoteFormScreen extends ConsumerStatefulWidget {
  const CreditNoteFormScreen({
    super.key,
    required this.bill,
    this.embedded = false,
    this.onSaved,
  });

  final Bill bill;
  final bool embedded;
  final VoidCallback? onSaved;

  @override
  ConsumerState<CreditNoteFormScreen> createState() =>
      _CreditNoteFormScreenState();
}

class _ReturnLine {
  _ReturnLine({
    required this.billItemId,
    required this.name,
    required this.maxQty,
    required this.originalQty,
    required this.rate,
    required this.discount,
  });

  final String billItemId;
  final String name;
  final int maxQty;
  final int originalQty;
  final int rate;
  final int discount;
  int qty = 0;

  int get proratedDiscount => proratedLineDiscountPaisa(
        originalDiscountPaisa: discount,
        originalQty: originalQty,
        returnedQty: qty,
      );

  int get lineTotal => qty > 0
      ? lineTotalPaisa(
          qty: qty,
          ratePaisa: rate,
          discountPaisa: proratedDiscount,
        )
      : 0;
}

class _CreditNoteFormScreenState extends ConsumerState<CreditNoteFormScreen> {
  final _reasonController = TextEditingController();
  bool _restock = true;
  bool _loading = false;
  List<_ReturnLine>? _lines;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  List<_ReturnLine> _buildLines(Map<String, int> returned) {
    return widget.bill.items.map((item) {
      final already = returned[item.id] ?? 0;
      final remaining = item.qty - already;
      return _ReturnLine(
        billItemId: item.id,
        name: item.nameSnapshot,
        maxQty: remaining,
        originalQty: item.qty,
        rate: item.rate,
        discount: item.discount,
      );
    }).where((line) => line.maxQty > 0).toList();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final lines = _lines ?? [];
    final selected = lines.where((line) => line.qty > 0).toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noReturnableQty)),
      );
      return;
    }
    if (selected.any((line) => line.qty > line.maxQty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.returnQtyExceeds)),
      );
      return;
    }

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.returnsOnlineOnly)),
        );
      }
      return;
    }

    final memberId = ref.read(authProvider).value?.member?.id;
    if (memberId == null) return;

    setState(() => _loading = true);
    try {
      final note = await ref.read(creditNotesRepositoryProvider).create(
            billId: widget.bill.id,
            createdByMemberId: memberId,
            restock: _restock,
            reason: _reasonController.text.trim(),
            lines: selected
                .map(
                  (line) => CreditNoteLineInput(
                    billItemId: line.billItemId,
                    qtyReturned: line.qty,
                    rate: line.rate,
                    discount: line.proratedDiscount,
                  ),
                )
                .toList(),
          );

      ref.invalidate(billDetailProvider(widget.bill.id));
      ref.invalidate(billReturnedQtyProvider(widget.bill.id));
      if (widget.bill.customerId != null) {
        ref.invalidate(customerLedgerProvider(widget.bill.customerId!));
        ref.invalidate(totalDuesProvider);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.creditNoteSaved),
            action: SnackBarAction(
              label: l10n.shareViaWhatsApp,
              onPressed: () => exportCreditNoteAsPng(
                ref,
                context,
                note,
                customerLabel: widget.bill.customerShopName,
              ),
            ),
          ),
        );
        if (widget.onSaved != null) {
          widget.onSaved!();
        } else {
          Navigator.pop(context, true);
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.actionFailed),
            backgroundColor: BsColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final returnedAsync = ref.watch(billReturnedQtyProvider(widget.bill.id));

    final body = returnedAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(child: Text(l10n.loadingFailed)),
      data: (returned) {
        _lines ??= _buildLines(returned);
        final lines = _lines!;
        if (lines.isEmpty) {
          return Center(child: Text(l10n.noReturnableQty));
        }

        final total = itemsTotalPaisa(lines.map((l) => l.lineTotal));

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '${l10n.returnItems} — ${widget.bill.billNo}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            for (final line in lines)
              Card(
                child: ListTile(
                  title: Text(line.name),
                  subtitle: Text('${l10n.qtyReturned}: max ${line.maxQty}'),
                  trailing: SizedBox(
                    width: 72,
                    child: TextFormField(
                      initialValue: line.qty == 0 ? '' : '${line.qty}',
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.qty,
                        isDense: true,
                      ),
                      onChanged: (value) {
                        line.qty = int.tryParse(value) ?? 0;
                        if (line.qty < 0) line.qty = 0;
                        if (line.qty > line.maxQty) line.qty = line.maxQty;
                        setState(() {});
                      },
                    ),
                  ),
                ),
              ),
            SwitchListTile(
              title: Text(l10n.restockInventory),
              value: _restock,
              onChanged: (value) => setState(() => _restock = value),
            ),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(labelText: l10n.returnReason),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Text(
              '${l10n.grandTotal}: ${formatNpr(Paisa(total), showPaisa: false)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: Text(l10n.submitReturn),
            ),
            if (_loading) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
          ],
        );
      },
    );

    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.returnItems)),
      body: body,
    );
  }
}
