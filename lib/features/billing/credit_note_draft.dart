import '../../core/utils/bill_totals.dart';
import '../../domain/models/bill.dart';
import '../../domain/models/credit_note.dart';

class CreditNoteLineDraft {
  CreditNoteLineDraft({
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

  CreditNoteLineInput toInput() {
    return CreditNoteLineInput(
      billItemId: billItemId,
      qtyReturned: qty,
      rate: rate,
      discount: proratedDiscount,
    );
  }
}

/// Builds returnable lines from a bill and already-returned quantities.
List<CreditNoteLineDraft> buildReturnableLines(
  Bill bill,
  Map<String, int> returnedQty,
) {
  return bill.items
      .map((item) {
        final already = returnedQty[item.id] ?? 0;
        final remaining = item.qty - already;
        return CreditNoteLineDraft(
          billItemId: item.id,
          name: item.nameSnapshot,
          maxQty: remaining,
          originalQty: item.qty,
          rate: item.rate,
          discount: item.discount,
        );
      })
      .where((line) => line.maxQty > 0)
      .toList();
}

enum CreditNoteValidationError { noLines, qtyExceedsMax, offlineNotAllowed }

CreditNoteValidationError? validateCreditNoteSubmit({
  required List<CreditNoteLineDraft> lines,
  required bool isOnline,
}) {
  final selected = lines.where((line) => line.qty > 0).toList();
  if (selected.isEmpty) return CreditNoteValidationError.noLines;
  if (selected.any((line) => line.qty > line.maxQty)) {
    return CreditNoteValidationError.qtyExceedsMax;
  }
  if (!isOnline) return CreditNoteValidationError.offlineNotAllowed;
  return null;
}
