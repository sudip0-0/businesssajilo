import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/ui/adaptive_sheet.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/submit_action.dart';
import '../../core/utils/money.dart';
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
  bool _quoteLoading = true;
  bool _noAcceptedQuote = false;
  BillFromOrderDraft? _draft;

  @override
  void initState() {
    super.initState();
    _loadQuote();
  }

  Future<void> _loadQuote() async {
    final draft = await loadBillFromOrderDraft(
      ref.read(billingRefProvider),
      widget.orderId,
    );
    if (!mounted) return;
    if (draft == null) {
      setState(() {
        _quoteLoading = false;
        _noAcceptedQuote = true;
      });
      return;
    }
    setState(() {
      _draft = draft;
      _quoteLoading = false;
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final draft = _draft;
    if (draft == null || draft.lines.isEmpty) return;

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
    final draft = _draft;

    if (_noAcceptedQuote) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: ErrorState(message: l10n.noAcceptedQuote),
      );
    }
    if (_quoteLoading || draft == null) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

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
            l10n.generateBill,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          ...draft.lines.map(
            (line) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(line.nameSnapshot),
              subtitle: Text(
                '${line.qty} × ${formatNpr(Paisa(line.rate), showPaisa: false)}',
              ),
              trailing: Text(
                formatNpr(Paisa(line.lineTotal), showPaisa: false),
              ),
            ),
          ),
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
