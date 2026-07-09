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
