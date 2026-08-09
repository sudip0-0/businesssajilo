import 'bill_draft_line.dart';
import 'bill_form_draft.dart';

enum BillFormValidationError {
  noLines,
  invalidLineDiscount,
  invalidBillDiscount,
  negativeGrandTotal,
}

/// Validates a bill draft before opening the payment sheet / save.
BillFormValidationError? validateBillForm(BillFormDraft draft) {
  if (draft.lines.isEmpty) return BillFormValidationError.noLines;
  if (draft.lines.any((l) => !l.discountValid)) {
    return BillFormValidationError.invalidLineDiscount;
  }
  final discount = draft.billDiscount;
  final items = draft.itemsTotal;
  if (discount < 0 || discount > items) {
    return BillFormValidationError.invalidBillDiscount;
  }
  if (draft.grandTotal < 0) return BillFormValidationError.negativeGrandTotal;
  return null;
}

/// Lines whose quantity exceeds the product's tracked on-hand stock.
///
/// Used to warn (but not block) overselling at the counter. Products without
/// tracked stock are skipped.
List<BillDraftLine> oversellingLines(BillFormDraft draft) {
  return draft.lines
      .where((l) => l.qty > l.product.stockCached)
      .toList();
}
