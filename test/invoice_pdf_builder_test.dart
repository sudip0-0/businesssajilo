import 'package:businesssajilo/core/invoicing/invoice_document.dart';
import 'package:businesssajilo/core/invoicing/invoice_image_builder.dart';
import 'package:businesssajilo/core/invoicing/invoice_pdf_builder.dart';
import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/domain/models/bill.dart';
import 'package:businesssajilo/domain/models/bill_item.dart';
import 'package:businesssajilo/domain/models/business.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

InvoiceDocument _sampleDoc() {
  final business = Business(
    id: 'biz1',
    name: 'Test Shop',
    phone: '9800000000',
    address: 'Kathmandu',
  );
  final bill = Bill(
    id: 'b1',
    businessId: 'biz1',
    billNo: 'BS-0001',
    itemsTotal: 10000,
    grandTotal: 10000,
    status: BillStatus.due,
    createdBy: 'm1',
    items: const [
      BillItem(
        id: 'i1',
        billId: 'b1',
        productId: 'p1',
        nameSnapshot: 'Cola',
        qty: 2,
        rate: 5000,
        lineTotal: 10000,
      ),
    ],
  );
  return InvoiceDocument.fromBill(
    business: business,
    bill: bill,
    customerLabel: 'Ram Store',
    statusLabel: 'Due',
    locale: const Locale('en'),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('InvoicePdfBuilder produces non-empty bytes', () async {
    final bytes = await const InvoicePdfBuilder().build(_sampleDoc());
    expect(bytes, isNotEmpty);
    expect(bytes.length, greaterThan(100));
  });

  test(
    'InvoiceImageBuilder produces PNG bytes',
    () async {
      // Printing.raster uses a platform channel; PNG encode is covered by
      // test/pdf_raster_isolate_test.dart. Full raster covered in integration.
    },
    skip: 'Requires printing platform channel',
  );

  test('credit note document includes line items', () {
    final doc = InvoiceDocument(
      business: Business(id: 'biz1', name: 'Shop'),
      kind: InvoiceDocumentKind.creditNote,
      documentNo: 'CN-0001',
      customerLabel: 'Customer',
      createdAt: DateTime(2026, 1, 1),
      statusLabel: 'Credit note',
      lines: const [
        InvoiceLine(
          name: 'Cola',
          qty: 1,
          rate: 5000,
          discount: 0,
          lineTotal: 5000,
        ),
      ],
      itemsTotal: 5000,
      discount: 0,
      grandTotal: 5000,
      locale: const Locale('en'),
    );
    expect(doc.lines.length, 1);
    expect(doc.titleLabel, isNotEmpty);
  });
}
