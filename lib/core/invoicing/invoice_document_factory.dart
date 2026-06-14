import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../domain/enums.dart';
import '../../domain/models/bill.dart';
import '../../domain/models/business.dart';
import '../../domain/models/credit_note.dart';
import 'invoice_document.dart';
import 'invoice_export_service.dart';

/// Builds [InvoiceDocument] instances with localized labels.
class InvoiceDocumentFactory {
  const InvoiceDocumentFactory();

  InvoiceDocument fromBill({
    required Business business,
    required Bill bill,
    required AppLocalizations l10n,
    required Locale locale,
  }) {
    return InvoiceDocument.fromBill(
      business: business,
      bill: bill,
      customerLabel: bill.customerShopName ?? l10n.walkIn,
      statusLabel: _billStatusLabel(bill.status, l10n),
      locale: locale,
      provisionalNotice: l10n.provisionalBillNotice,
      thankYou: l10n.invoiceThankYou,
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
