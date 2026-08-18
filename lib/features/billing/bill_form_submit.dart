import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/adaptive_sheet.dart';
import '../../core/ui/bs_snackbar.dart';
import '../../domain/enums.dart';
import '../../domain/models/bill.dart';
import 'bill_form_draft.dart';
import 'bill_form_save.dart';
import 'bill_form_validation.dart';
import 'invalidate_billing.dart';
import 'bill_payment_sheet.dart';
import 'invoice_export_actions.dart';

/// Shared bill-form submit: validate → payment sheet → persist → notify/export.
///
/// Pass [payment] to skip the payment sheet. Save-as-due uses [forceStatus]
/// instead of collecting status on the form.
Future<Bill?> submitBillForm({
  required WidgetRef ref,
  required BuildContext context,
  required BillFormDraft draft,
  BillStatus? forceStatus,
  BillPaymentResult? payment,
  String? fallbackCustomerId,
  String? initialCustomerName,
  String? orderId,
  bool exportAfterSave = false,
  VoidCallback? onSaved,
  bool popOnSuccess = false,
  Color? snackbarErrorColor,
}) async {
  final l10n = AppLocalizations.of(context);
  final validationError = validateBillForm(draft);
  if (validationError != null) {
    showBsSnackBar(
      context,
      message: billFormValidationMessage(l10n, validationError),
      backgroundColor: snackbarErrorColor ?? BsColors.danger,
    );
    return null;
  }

  final oversell = oversellingLines(draft);
  if (oversell.isNotEmpty) {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.oversellConfirmTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.oversellConfirmBody),
            const SizedBox(height: 12),
            for (final line in oversell)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '${line.product.name} — ${l10n.qty}: ${line.qty} · '
                  '${l10n.availableStock}: ${line.product.stockCached}',
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.oversellContinue),
          ),
        ],
      ),
    );
    if (proceed != true || !context.mounted) return null;
  }

  BillPaymentResult? paymentResult = payment;
  if (paymentResult == null) {
    if (forceStatus == BillStatus.due) {
      paymentResult = duePaymentForDraft(draft);
    } else {
      paymentResult = await showAdaptiveSheet<BillPaymentResult>(
        context: context,
        title: l10n.saveBill,
        child: BillPaymentSheet(
          grandTotal: draft.grandTotal,
          initialCustomerId: draft.customerId,
          initialCustomerName: initialCustomerName,
          initialGuestName: draft.guestName,
        ),
      );
    }
  }
  if (paymentResult == null) return null;

  try {
    final savedBill = await saveBillForm(
      ref.read(billingRefProvider),
      draft: draft,
      payment: paymentResult,
      fallbackCustomerId: fallbackCustomerId,
      orderId: orderId,
    );

    if (!context.mounted) return savedBill;
    showBsSnackBar(context, message: l10n.billSaved);
    if (exportAfterSave) {
      await exportBillAfterSave(ref, context, savedBill);
    }
    if (!context.mounted) return savedBill;
    onSaved?.call();
    if (popOnSuccess) Navigator.pop(context, true);
    return savedBill;
  } catch (e) {
    if (context.mounted) {
      showBsSnackBar(
        context,
        message: AppFailure.from(e).message(l10n),
        backgroundColor: snackbarErrorColor ?? BsColors.danger,
      );
    }
    return null;
  }
}
