import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/bill_totals.dart';
import '../../data/repositories/bills_repository.dart';
import '../../data/repositories/quotes_repository.dart';
import '../../domain/models/bill.dart';
import '../../domain/models/quote.dart';
import '../auth/providers/auth_provider.dart';
import 'bill_payment_result.dart';
import 'invalidate_billing.dart';

class BillFromOrderDraft {
  const BillFromOrderDraft({
    required this.lines,
    required this.itemsTotal,
    this.discount = 0,
  });

  final List<BillLineInput> lines;
  final int itemsTotal;
  final int discount;

  int get grandTotal => itemsTotal - discount;

  bool get isEmpty => lines.isEmpty;
}

/// Maps an accepted [Quote] into bill lines (pure; used by load + tests).
BillFromOrderDraft billFromOrderDraftFromQuote(Quote quote) {
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
  return BillFromOrderDraft(
    lines: lines,
    // Recompute from line items rather than trusting the stored quote total.
    itemsTotal: itemsTotalPaisa(lines.map((l) => l.lineTotal)),
    discount: 0,
  );
}

/// Loads the latest accepted quote for [orderId], or `null` if none.
Future<BillFromOrderDraft?> loadBillFromOrderDraft(
  Ref ref,
  String orderId,
) async {
  final quote = await ref
      .read(quotesRepositoryProvider)
      .latestAccepted(orderId);
  if (quote == null) return null;
  return billFromOrderDraftFromQuote(quote);
}

Future<Bill> saveBillFromOrder(
  Ref ref, {
  required String orderId,
  required String customerId,
  required BillFromOrderDraft draft,
  required BillPaymentResult payment,
}) async {
  final memberId = ref.read(authProvider).value?.member?.id;
  if (memberId == null) {
    throw StateError('Not authenticated');
  }
  if (draft.lines.isEmpty) {
    throw StateError('No bill lines');
  }
  final bill = await ref
      .read(billsRepositoryProvider)
      .createFromOrder(
        orderId: orderId,
        customerId: customerId,
        createdByMemberId: memberId,
        status: payment.status,
        itemsTotal: draft.itemsTotal,
        discount: draft.discount,
        grandTotal: draft.grandTotal,
        lines: draft.lines,
        paymentMethod: payment.paymentMethod,
        paymentRefNote: payment.paymentRefNote,
        paymentAmount: payment.paymentAmount,
      );
  invalidateAfterBillSaved(ref, customerId: customerId, orderId: orderId);
  return bill;
}
