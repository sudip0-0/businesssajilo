import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/invoicing/invoice_document.dart';
import '../../core/invoicing/invoice_document_factory.dart';
import '../../core/invoicing/invoice_export_service.dart';
import '../../core/l10n/app_localizations.dart';
import '../../domain/models/bill.dart';
import '../../domain/models/credit_note.dart';
import '../auth/providers/auth_provider.dart';

/// Loads business profile and shares/prints a bill document.
Future<void> exportBillAsPng(
  WidgetRef ref,
  BuildContext context,
  Bill bill,
) async {
  await _exportBill(ref, context, bill, (service, doc, l10n) async {
    final factory = ref.read(invoiceDocumentFactoryProvider);
    await service.sharePng(
      doc,
      subject: doc.documentNo,
      text: factory.shareCaption(doc, l10n),
    );
  });
}

Future<void> exportBillPrint(
  WidgetRef ref,
  BuildContext context,
  Bill bill,
) async {
  await _exportBill(ref, context, bill, (service, doc, _) async {
    await service.printPdf(doc);
  });
}

Future<void> exportBillPdfDownload(
  WidgetRef ref,
  BuildContext context,
  Bill bill,
) async {
  await _exportBill(ref, context, bill, (service, doc, _) async {
    await service.downloadPdf(doc);
  });
}

Future<void> exportBillAfterSave(
  WidgetRef ref,
  BuildContext context,
  Bill bill, {
  bool sharePng = true,
  bool offerPrint = true,
}) async {
  if (sharePng) {
    await exportBillAsPng(ref, context, bill);
  }
  if (offerPrint && context.mounted) {
    await exportBillPrint(ref, context, bill);
  }
}

typedef _ExportAction =
    Future<void> Function(
      InvoiceExportService service,
      InvoiceDocument doc,
      AppLocalizations l10n,
    );

Future<void> _exportBill(
  WidgetRef ref,
  BuildContext context,
  Bill bill,
  _ExportAction action,
) async {
  final l10n = AppLocalizations.of(context);
  final business = await ref.read(currentBusinessProvider.future);
  if (business == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.actionFailed)));
    }
    return;
  }

  final factory = ref.read(invoiceDocumentFactoryProvider);
  final service = ref.read(invoiceExportServiceProvider);
  final doc = factory.fromBill(
    business: business,
    bill: bill,
    l10n: l10n,
    locale: Localizations.localeOf(context),
  );
  await action(service, doc, l10n);
}

Future<void> exportCreditNoteAsPng(
  WidgetRef ref,
  BuildContext context,
  CreditNote note, {
  String? customerLabel,
}) async {
  await _exportCreditNote(
    ref,
    context,
    note,
    customerLabel: customerLabel,
    action: (service, doc, l10n) async {
      final factory = ref.read(invoiceDocumentFactoryProvider);
      await service.sharePng(
        doc,
        subject: doc.documentNo,
        text: factory.shareCaption(doc, l10n),
      );
    },
  );
}

Future<void> _exportCreditNote(
  WidgetRef ref,
  BuildContext context,
  CreditNote note, {
  String? customerLabel,
  required _ExportAction action,
}) async {
  final l10n = AppLocalizations.of(context);
  final business = await ref.read(currentBusinessProvider.future);
  if (business == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.actionFailed)));
    }
    return;
  }

  final factory = ref.read(invoiceDocumentFactoryProvider);
  final service = ref.read(invoiceExportServiceProvider);
  final doc = factory.fromCreditNote(
    business: business,
    note: note,
    customerLabel: customerLabel ?? l10n.walkIn,
    l10n: l10n,
    locale: Localizations.localeOf(context),
  );
  await action(service, doc, l10n);
}
