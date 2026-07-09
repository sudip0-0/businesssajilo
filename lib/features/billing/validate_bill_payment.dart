import '../../domain/enums.dart';
import 'bill_payment_result.dart';

enum BillPaymentValidationError {
  amountRequired,
  amountNotPositive,
  amountExceedsTotal,
  selectCustomer,
  walkInCreditNotAllowed,
}

/// Validates payment-sheet inputs before building a [BillPaymentResult].
///
/// [partialAmountPaisa] is required when [status] is [BillStatus.partial].
/// Partial covering the full total is treated as paid for walk-in / customer rules.
BillPaymentValidationError? validateBillPayment({
  required BillStatus status,
  required int grandTotal,
  required bool walkIn,
  String? customerId,
  int? partialAmountPaisa,
}) {
  var effective = status;
  if (status == BillStatus.partial) {
    if (partialAmountPaisa == null) {
      return BillPaymentValidationError.amountRequired;
    }
    if (partialAmountPaisa <= 0) {
      return BillPaymentValidationError.amountNotPositive;
    }
    if (partialAmountPaisa > grandTotal) {
      return BillPaymentValidationError.amountExceedsTotal;
    }
    if (partialAmountPaisa == grandTotal) {
      effective = BillStatus.paid;
    }
  }

  if (!walkIn && customerId == null && effective != BillStatus.due) {
    return BillPaymentValidationError.selectCustomer;
  }

  if (walkIn && effective != BillStatus.paid) {
    return BillPaymentValidationError.walkInCreditNotAllowed;
  }

  return null;
}

/// Normalizes status (partial covering full → paid) and derives paymentAmount.
BillPaymentResult buildBillPaymentResult({
  required BillStatus status,
  required int grandTotal,
  required bool walkIn,
  String? customerId,
  int? partialAmountPaisa,
  PaymentMethod paymentMethod = PaymentMethod.cash,
  String? paymentRefNote,
}) {
  var resolved = status;
  if (resolved == BillStatus.partial &&
      partialAmountPaisa != null &&
      partialAmountPaisa == grandTotal) {
    resolved = BillStatus.paid;
  }

  final paymentAmount = switch (resolved) {
    BillStatus.partial => partialAmountPaisa,
    BillStatus.paid => grandTotal,
    BillStatus.due => null,
  };

  return BillPaymentResult(
    status: resolved,
    customerId: walkIn ? null : customerId,
    paymentAmount: paymentAmount,
    paymentMethod: paymentMethod,
    paymentRefNote: paymentRefNote,
  );
}
