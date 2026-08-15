import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/utils/bill_customer_label.dart';
import '../../domain/enums.dart';
import '../../domain/models/bill.dart';
import '../../domain/models/business.dart';
import '../../domain/models/credit_note.dart';
import 'invoice_document.dart';
import 'invoice_export_service.dart';
import 'invoice_labels.dart';

/// Builds [InvoiceDocument] instances with localized labels.
class InvoiceDocumentFactory {
  const InvoiceDocumentFactory();

  InvoiceLabels labelsFrom(
    AppLocalizations l10n, {
    InvoiceDocumentKind kind = InvoiceDocumentKind.bill,
  }) {
    return InvoiceLabels(
      title: switch (kind) {
        InvoiceDocumentKind.bill => l10n.invoiceTitle,
        InvoiceDocumentKind.creditNote => l10n.creditNote.toUpperCase(),
      },
      billNo: l10n.invoiceNumber,
      date: l10n.invoiceDate,
      customer: l10n.invoiceCustomer,
      name: l10n.name,
      address: l10n.address,
      item: l10n.invoiceParticulars,
      qty: l10n.qty,
      rate: l10n.rate,
      amount: l10n.invoiceAmount,
      subtotal: l10n.subtotal,
      discount: l10n.discount,
      billDiscount: l10n.billDiscount,
      grandTotal: l10n.grandTotal,
      total: l10n.total,
      sn: l10n.sn,
      inWords: l10n.invoiceInWords,
      authorized: l10n.invoiceAuthorized,
      amountPaid: l10n.amountPaid,
      remainingDue: l10n.remainingDue,
    );
  }

  InvoiceDocument fromBill({
    required Business business,
    required Bill bill,
    required AppLocalizations l10n,
    required Locale locale,
    int? amountReceived,
    String? customerAddress,
  }) {
    return InvoiceDocument.fromBill(
      business: business,
      bill: bill,
      customerLabel: billCustomerLabel(bill, walkInLabel: l10n.walkIn),
      statusLabel: _billStatusLabel(bill.status, l10n),
      locale: locale,
      labels: labelsFrom(l10n),
      provisionalNotice: l10n.provisionalBillNotice,
      thankYou: l10n.invoiceThankYou,
      amountReceived: amountReceived,
      customerAddress: customerAddress,
    );
  }

  InvoiceDocument fromCreditNote({
    required Business business,
    required CreditNote note,
    required String customerLabel,
    required AppLocalizations l10n,
    required Locale locale,
  }) {
    return InvoiceDocument(
      business: business,
      kind: InvoiceDocumentKind.creditNote,
      documentNo: note.creditNo,
      customerLabel: customerLabel,
      createdAt: note.createdAt ?? DateTime.now(),
      statusLabel: l10n.creditNote,
      lines: note.items
          .map(
            (i) => InvoiceLine(
              name: i.nameSnapshot,
              qty: i.qtyReturned,
              rate: i.rate,
              discount: i.discount,
              lineTotal: i.lineTotal,
            ),
          )
          .toList(),
      itemsTotal: note.itemsTotal,
      discount: note.discount,
      grandTotal: note.grandTotal,
      locale: locale,
      labels: labelsFrom(l10n, kind: InvoiceDocumentKind.creditNote),
      footerNote: l10n.invoiceThankYou,
    );
  }

  String shareCaption(InvoiceDocument doc, AppLocalizations l10n) {
    final total = formatNprForCaption(doc.grandTotal);
    return '${doc.documentNo} — ${doc.customerLabel} — $total';
  }

  String _billStatusLabel(BillStatus status, AppLocalizations l10n) =>
      switch (status) {
        BillStatus.paid => l10n.paid,
        BillStatus.partial => l10n.partial,
        BillStatus.due => l10n.due,
      };

  String formatNprForCaption(int paisa) {
    final rupees = paisa / 100;
    return 'Rs ${rupees.toStringAsFixed(0)}';
  }
}

final invoiceDocumentFactoryProvider = Provider((ref) {
  return const InvoiceDocumentFactory();
});

final invoiceExportServiceProvider = Provider((ref) {
  return const InvoiceExportService();
});
