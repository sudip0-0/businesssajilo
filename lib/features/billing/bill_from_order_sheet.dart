import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/ui/error_state.dart';
import '../../core/utils/bill_totals.dart';
import '../../core/utils/money.dart';
import '../../data/repositories/bills_repository.dart';
import '../../data/repositories/quotes_repository.dart';
import '../auth/providers/auth_provider.dart';
import '../billing/providers.dart';
import '../customers/providers.dart';
import '../orders/providers.dart';
import 'bill_payment_sheet.dart';

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
  int _itemsTotal = 0;
  int _discount = 0;
  List<BillLineInput> _lines = [];

  @override
  void initState() {
    super.initState();
    _loadQuote();
  }

  Future<void> _loadQuote() async {
    final quote = await ref
        .read(quotesRepositoryProvider)
        .latestAccepted(widget.orderId);
    if (!mounted) return;
    if (quote == null) {
      setState(() {
        _quoteLoading = false;
        _noAcceptedQuote = true;
      });
      return;
    }
    final lines = quote.items
        .map(
          (item) => BillLineInput(
            productId: item.productId,
            nameSnapshot: item.productName ?? '—',
            qty: item.qty,
            rate: item.rate,
            discount: item.discount,
            lineTotal: item.lineTotal,
          ),
        )
        .toList();
    setState(() {
      _lines = lines;
      // Recompute from line items rather than trusting the stored quote total.
      _itemsTotal = itemsTotalPaisa(lines.map((l) => l.lineTotal));
      _discount = 0;
      _quoteLoading = false;
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final member = ref.read(authProvider).value?.member;
    if (member == null || _lines.isEmpty) return;

    final payment = await showModalBottomSheet<BillPaymentResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BillPaymentSheet(grandTotal: _itemsTotal - _discount),
    );
    if (payment == null) return;

    setState(() => _loading = true);
    try {
      await ref.read(billsRepositoryProvider).createFromOrder(
            orderId: widget.orderId,
            customerId: widget.customerId,
            createdByMemberId: member.id,
            status: payment.status,
            itemsTotal: _itemsTotal,
            discount: _discount,
            grandTotal: _itemsTotal - _discount,
            lines: _lines,
            paymentMethod: payment.paymentMethod,
            paymentRefNote: payment.paymentRefNote,
            paymentAmount: payment.paymentAmount,
          );
      ref.invalidate(billListProvider);
      ref.invalidate(todaysSalesProvider);
      ref.invalidate(todaysBillCountProvider);
      ref.invalidate(totalDuesProvider);
      ref.invalidate(orderDetailProvider(widget.orderId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.billSaved)),
        );
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.actionFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_noAcceptedQuote) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: ErrorState(message: l10n.noAcceptedQuote),
      );
    }
    if (_quoteLoading) {
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
          Text(l10n.generateBill, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ..._lines.map(
            (line) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(line.nameSnapshot),
              subtitle: Text('${line.qty} × ${formatNpr(Paisa(line.rate), showPaisa: false)}'),
              trailing: Text(formatNpr(Paisa(line.lineTotal), showPaisa: false)),
            ),
          ),
          Text(
            '${l10n.grandTotal}: ${formatNpr(Paisa(_itemsTotal - _discount), showPaisa: false)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _loading || _lines.isEmpty ? null : _save,
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
