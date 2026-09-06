import '../../core/utils/bill_totals.dart';
import 'bill_draft_line.dart';
import 'bill_form_draft.dart';

enum BillFormValidationError {
  noLines,
  invalidMoneyInput,
  invalidLineDiscount,
  invalidBillDiscount,
  negativeGrandTotal,
}

/// Validates a bill draft before opening the payment sheet / save.
BillFormValidationError? validateBillForm(BillFormDraft draft) {
  if (draft.lines.isEmpty) return BillFormValidationError.noLines;
  if (!draft.billDiscountInputValid ||
      draft.lines.any((l) => !l.rateInputValid || !l.discountInputValid)) {
    return BillFormValidationError.invalidMoneyInput;
  }
  try {
    if (draft.lines.any(
      (l) => tryLineGrossPaisa(qty: l.qty, ratePaisa: l.rate) == null,
    )) {
      return BillFormValidationError.invalidMoneyInput;
    }
    if (draft.lines.any((l) => !l.discountValid)) {
      return BillFormValidationError.invalidLineDiscount;
    }
    final discount = draft.billDiscount;
    final items = draft.itemsTotal;
    if (discount < 0 || discount > items) {
      return BillFormValidationError.invalidBillDiscount;
    }
    if (draft.grandTotal < 0) return BillFormValidationError.negativeGrandTotal;
  } on ArgumentError {
    return BillFormValidationError.invalidMoneyInput;
  }
  return null;
}

/// Lines whose quantity exceeds the product's tracked on-hand stock.
///
/// Used to warn (but not block) overselling at the counter.
List<BillDraftLine> oversellingLines(BillFormDraft draft) {
  return draft.lines.where((l) => l.qty > l.product.stockCached).toList();
}
