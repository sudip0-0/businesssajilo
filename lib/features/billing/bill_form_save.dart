import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../data/repositories/bills_repository.dart';
import '../../domain/enums.dart';
import '../../domain/models/bill.dart';
import '../auth/providers/auth_provider.dart';
import 'bill_form_draft.dart';
import 'bill_form_validation.dart';
import 'bill_payment_result.dart';
import 'invalidate_billing.dart';

String billFormValidationMessage(
  AppLocalizations l10n,
  BillFormValidationError error,
) {
  return switch (error) {
    BillFormValidationError.noLines => l10n.noBillLines,
    BillFormValidationError.invalidLineDiscount => l10n.discountExceedsLine,
    BillFormValidationError.invalidBillDiscount => l10n.discountExceedsItems,
    BillFormValidationError.negativeGrandTotal => l10n.amountMustBePositive,
  };
}

/// Web "save draft" payment: due status with the draft's customer.
BillPaymentResult duePaymentForDraft(BillFormDraft draft) {
  return BillPaymentResult(
    status: BillStatus.due,
    customerId: draft.customerId,
  );
}

/// Persists a validated bill draft via [BillsRepository.create].
Future<Bill> saveBillForm(
  Ref ref, {
  required BillFormDraft draft,
  required BillPaymentResult payment,
  String? fallbackCustomerId,
}) async {
  final memberId = ref.read(authProvider).value?.member?.id;
  if (memberId == null) {
    throw StateError('Not authenticated');
  }
  final customerId =
      payment.customerId ?? fallbackCustomerId ?? draft.customerId;
  final bill = await ref
      .read(billsRepositoryProvider)
      .create(
        createdByMemberId: memberId,
        customerId: customerId,
        status: payment.status,
        itemsTotal: draft.itemsTotal,
        discount: draft.billDiscount,
        grandTotal: draft.grandTotal,
        lines: draft.toLineInputs(),
        paymentMethod: payment.paymentMethod,
        paymentRefNote: payment.paymentRefNote,
        paymentAmount: payment.paymentAmount,
      );
  invalidateAfterBillSaved(ref, customerId: customerId);
  return bill;
}
