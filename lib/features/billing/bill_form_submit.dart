import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/enums.dart';
import '../../domain/models/bill.dart';
import 'bill_form_draft.dart';
import 'bill_form_save.dart';
import 'bill_form_validation.dart';
import 'invalidate_billing.dart';
import 'bill_payment_sheet.dart';
import 'invoice_export_actions.dart';
import '../../core/ui/adaptive_sheet.dart';

/// Shared bill-form submit: validate → payment sheet → persist → notify/export.
Future<Bill?> submitBillForm({
  required WidgetRef ref,
  required BuildContext context,
  required BillFormDraft draft,
  BillStatus? forceStatus,
  String? fallbackCustomerId,
  bool exportAfterSave = false,
  VoidCallback? onSaved,
  bool popOnSuccess = false,
  Color? snackbarErrorColor,
}) async {
  final l10n = AppLocalizations.of(context);
  final validationError = validateBillForm(draft);
  if (validationError != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(billFormValidationMessage(l10n, validationError)),
        backgroundColor: snackbarErrorColor ?? BsColors.danger,
      ),
    );
    return null;
  }

  BillPaymentResult? paymentResult;
  if (forceStatus == BillStatus.due) {
    paymentResult = duePaymentForDraft(draft);
  } else {
    paymentResult = await showAdaptiveSheet<BillPaymentResult>(
      context: context,
      title: l10n.saveBill,
      child: BillPaymentSheet(
        grandTotal: draft.grandTotal,
        initialCustomerId: draft.customerId,
      ),
    );
  }
  if (paymentResult == null) return null;

  try {
    final savedBill = await saveBillForm(
      ref.read(billingRefProvider),
      draft: draft,
      payment: paymentResult,
      fallbackCustomerId: fallbackCustomerId,
    );

    if (!context.mounted) return savedBill;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.billSaved)));
    if (exportAfterSave) {
      await exportBillAfterSave(ref, context, savedBill);
    }
    if (!context.mounted) return savedBill;
    onSaved?.call();
    if (popOnSuccess) Navigator.pop(context, true);
    return savedBill;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppFailure.from(e).message(l10n)),
          backgroundColor: snackbarErrorColor ?? BsColors.danger,
        ),
      );
    }
    return null;
  }
}
