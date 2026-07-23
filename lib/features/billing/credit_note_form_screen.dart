import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/network/supabase_health_probe.dart';
import '../../core/ui/submit_action.dart';
import '../../core/utils/bill_totals.dart';
import '../../core/utils/money.dart';
import '../../domain/models/bill.dart';
import 'credit_note_draft.dart';
import 'credit_note_providers.dart';
import 'invalidate_billing.dart';
import 'invoice_export_actions.dart';
import 'save_credit_note.dart';

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

class _CreditNoteFormScreenState extends ConsumerState<CreditNoteFormScreen> {
  final _reasonController = TextEditingController();
  bool _restock = true;
  bool _loading = false;
  List<CreditNoteLineDraft>? _lines;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final lines = _lines ?? [];

    final connectivity = await Connectivity().checkConnectivity();
    final hasLink = connectivity.any((r) => r != ConnectivityResult.none);
    final isOnline = hasLink && await isSupabaseReachable();

    final error = validateCreditNoteSubmit(lines: lines, isOnline: isOnline);
    if (error != null) {
      if (!mounted) return;
      final message = switch (error) {
        CreditNoteValidationError.noLines => l10n.noReturnableQty,
        CreditNoteValidationError.qtyExceedsMax => l10n.returnQtyExceeds,
        CreditNoteValidationError.offlineNotAllowed => l10n.returnsOnlineOnly,
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    final selected = lines.where((line) => line.qty > 0).toList();

    if (!mounted) return;
    setState(() => _loading = true);
    await runSubmitAction(
      context,
      action: () async {
        final note = await saveCreditNote(
          ref.read(billingRefProvider),
          bill: widget.bill,
          selected: selected,
          restock: _restock,
          reason: _reasonController.text.trim(),
        );

        if (!mounted) return;
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
      },
    );
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final returnedAsync = ref.watch(billReturnedQtyProvider(widget.bill.id));

    final body = returnedAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(child: Text(l10n.loadingFailed)),
      data: (returned) {
        _lines ??= buildReturnableLines(widget.bill, returned);
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
