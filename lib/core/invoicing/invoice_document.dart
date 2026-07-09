import 'package:flutter/material.dart';

import '../../domain/models/bill.dart';
import '../../domain/models/business.dart';

/// Kind of printable/shareable commercial document.
enum InvoiceDocumentKind { bill, creditNote }

/// Data required to render a bill or credit note for export.
class InvoiceDocument {
  const InvoiceDocument({
    required this.business,
    required this.documentNo,
    required this.customerLabel,
    required this.createdAt,
    required this.statusLabel,
    required this.lines,
    required this.itemsTotal,
    required this.discount,
    required this.grandTotal,
    required this.locale,
    this.kind = InvoiceDocumentKind.bill,
    this.pendingSync = false,
    this.provisionalNotice,
    this.footerNote,
  });

  factory InvoiceDocument.fromBill({
    required Business business,
    required Bill bill,
    required String customerLabel,
    required String statusLabel,
    required Locale locale,
    String? provisionalNotice,
    String? thankYou,
  }) {
    return InvoiceDocument(
      business: business,
      documentNo: bill.billNo,
      customerLabel: customerLabel,
      createdAt: bill.createdAt ?? DateTime.now(),
      statusLabel: statusLabel,
      lines: bill.items
          .map(
            (i) => InvoiceLine(
              name: i.nameSnapshot,
              qty: i.qty,
              rate: i.rate,
              discount: i.discount,
              lineTotal: i.lineTotal,
            ),
          )
          .toList(),
      itemsTotal: bill.itemsTotal,
      discount: bill.discount,
      grandTotal: bill.grandTotal,
      locale: locale,
      pendingSync: bill.pendingSync,
      provisionalNotice: bill.pendingSync ? provisionalNotice : null,
      footerNote: thankYou,
    );
  }

  final Business business;
  final InvoiceDocumentKind kind;
  final String documentNo;
  final String customerLabel;
  final DateTime createdAt;
  final String statusLabel;
  final List<InvoiceLine> lines;
  final int itemsTotal;
  final int discount;
  final int grandTotal;
  final Locale locale;
  final bool pendingSync;
  final String? provisionalNotice;
  final String? footerNote;

  String get titleLabel => switch (kind) {
    InvoiceDocumentKind.bill => 'INVOICE',
    InvoiceDocumentKind.creditNote => 'CREDIT NOTE',
  };

  String get businessDisplayName {
    if (locale.languageCode == 'ne' &&
        business.nameNp != null &&
        business.nameNp!.trim().isNotEmpty) {
      return business.nameNp!;
    }
    return business.name;
  }
}

class InvoiceLine {
  const InvoiceLine({
    required this.name,
    required this.qty,
    required this.rate,
    required this.discount,
    required this.lineTotal,
  });

  final String name;
  final int qty;
  final int rate;
  final int discount;
  final int lineTotal;
}
