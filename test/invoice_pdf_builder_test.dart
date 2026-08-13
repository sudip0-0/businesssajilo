import 'package:businesssajilo/core/invoicing/invoice_document.dart';
import 'package:businesssajilo/core/invoicing/invoice_labels.dart';
import 'package:businesssajilo/core/invoicing/invoice_paper_size.dart';
import 'package:businesssajilo/core/invoicing/invoice_pdf_builder.dart';
import 'package:businesssajilo/core/invoicing/pdf_fonts.dart';
import 'package:businesssajilo/core/utils/money.dart';
import 'package:businesssajilo/core/utils/rupees_in_words.dart';
import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/domain/models/bill.dart';
import 'package:businesssajilo/domain/models/bill_item.dart';
import 'package:businesssajilo/domain/models/business.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _labels = InvoiceLabels(
  title: 'INVOICE',
  billNo: 'Invoice No.',
  date: 'Date',
  customer: 'Customer',
  name: 'Name',
  address: 'Address',
  item: 'Particulars',
  qty: 'Qty',
  rate: 'Rate',
  amount: 'Amount',
  subtotal: 'Subtotal',
  discount: 'Discount',
  grandTotal: 'Grand Total',
  total: 'Total',
  sn: 'S.N.',
  inWords: 'In Words',
  authorized: 'Authorized',
  amountPaid: 'Amount paid',
  remainingDue: 'Remaining due',
);

InvoiceDocument _sampleDoc({
  int discount = 0,
  BillStatus status = BillStatus.due,
  String statusLabel = 'Due',
  int? amountReceived,
  String? customerAddress,
}) {
  final itemsTotal = 10000;
  final business = const Business(
    id: 'biz1',
    name: 'Test Shop',
    phone: '9800000000',
    address: 'Kathmandu',
  );
  final bill = Bill(
    id: 'b1',
    businessId: 'biz1',
    billNo: 'BS-0001',
    itemsTotal: itemsTotal,
    discount: discount,
    grandTotal: itemsTotal - discount,
    status: status,
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
    statusLabel: statusLabel,
    locale: const Locale('en'),
    labels: _labels,
    amountReceived: amountReceived,
    customerAddress: customerAddress,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(PdfFonts.clearCache);

  test('InvoicePdfBuilder produces non-empty A4 bytes', () async {
    final bytes = await const InvoicePdfBuilder().build(
      _sampleDoc(),
      paperSize: InvoicePaperSize.a4,
    );
    expect(bytes, isNotEmpty);
    expect(bytes.length, greaterThan(100));
  });

  test('InvoicePdfBuilder produces non-empty A5 bytes', () async {
    final bytes = await const InvoicePdfBuilder().build(
      _sampleDoc(),
      paperSize: InvoicePaperSize.a5,
    );
    expect(bytes, isNotEmpty);
    expect(bytes.length, greaterThan(100));
  });

  test('InvoicePdfBuilder renders discounted bill without throwing', () async {
    final bytes = await const InvoicePdfBuilder().build(
      _sampleDoc(discount: 500),
    );
    expect(bytes, isNotEmpty);
  });

  test('InvoicePdfBuilder renders due and partial status', () async {
    final due = await const InvoicePdfBuilder().build(_sampleDoc());
    final partial = await const InvoicePdfBuilder().build(
      _sampleDoc(
        status: BillStatus.partial,
        statusLabel: 'Partial',
        amountReceived: 4000,
      ),
    );
    expect(due, isNotEmpty);
    expect(partial, isNotEmpty);
  });

  test('InvoicePdfBuilder paginates a long item list', () async {
    final lines = [
      for (var i = 0; i < 28; i++)
        InvoiceLine(
          name: 'Item ${i + 1}',
          qty: 1,
          rate: 10000,
          discount: 0,
          lineTotal: 10000,
        ),
    ];
    final doc = InvoiceDocument(
      business: const Business(id: 'biz1', name: 'Test Shop'),
      documentNo: 'BS-0099',
      customerLabel: 'Ram Store',
      createdAt: DateTime(2026, 8, 13),
      statusLabel: 'Due',
      lines: lines,
      itemsTotal: 280000,
      discount: 0,
      grandTotal: 280000,
      locale: const Locale('en'),
      labels: _labels,
    );
    final bytes = await const InvoicePdfBuilder().build(doc);
    expect(bytes, isNotEmpty);
  });

  test('InvoicePdfBuilder renders Nepali Unicode without throwing', () async {
    final doc = InvoiceDocument.fromBill(
      business: const Business(
        id: 'biz1',
        name: 'राम स्टोर',
        phone: '9800000000',
        address: 'काठमाडौं',
      ),
      bill: const Bill(
        id: 'b1',
        businessId: 'biz1',
        billNo: 'BS-0001',
        itemsTotal: 10000,
        grandTotal: 10000,
        status: BillStatus.due,
        createdBy: 'm1',
        items: [
          BillItem(
            id: 'i1',
            billId: 'b1',
            productId: 'p1',
            nameSnapshot: 'कोला',
            qty: 2,
            rate: 5000,
            lineTotal: 10000,
          ),
        ],
      ),
      customerLabel: 'हरि बहादुर',
      statusLabel: 'बाँकी',
      locale: const Locale('ne'),
      labels: const InvoiceLabels(
        title: 'बिल',
        billNo: 'बिल नं.',
        date: 'मिति',
        customer: 'ग्राहक',
        name: 'नाम',
        address: 'ठेगाना',
        item: 'विवरण',
        qty: 'मात्रा',
        rate: 'दर',
        amount: 'रकम',
        subtotal: 'जम्मा',
        discount: 'छुट',
        grandTotal: 'कुल',
        total: 'जम्मा',
        sn: 'क्र.सं.',
        inWords: 'अक्षरेपी',
        authorized: 'प्रमाणित',
        amountPaid: 'भुक्तानी रकम',
        remainingDue: 'बाँकी रकम',
      ),
    );
    final bytes = await const InvoicePdfBuilder().build(doc);
    expect(bytes, isNotEmpty);
  });

  test(
    'InvoiceImageBuilder rasterizes the selected paper size',
    () async {
      // Printing.raster uses a platform channel; PNG encode is covered by
      // test/pdf_raster_isolate_test.dart. Full raster covered in integration.
    },
    skip: 'Requires printing platform channel',
  );

  test('credit note document includes line items', () {
    final doc = InvoiceDocument(
      business: const Business(id: 'biz1', name: 'Shop'),
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
      labels: _labels,
    );
    expect(doc.lines.length, 1);
    expect(doc.titleLabel, isNotEmpty);
  });

  test('partial invoice keeps remaining due from amount received', () {
    final doc = _sampleDoc(
      status: BillStatus.partial,
      statusLabel: 'Partial',
      amountReceived: 4000,
    );
    expect(doc.showPartialReceived, isTrue);
    expect(doc.remainingDue, 6000);
  });

  test('invoice document carries customer address', () {
    final doc = _sampleDoc(customerAddress: 'Bharatpur-10, Chitwan');
    expect(doc.customerAddress, 'Bharatpur-10, Chitwan');
  });

  test('print amounts use grouping without currency symbol or paisa', () {
    expect(formatNpr(Paisa(10000), showSymbol: false, showPaisa: false), '100');
    expect(
      formatNpr(Paisa(690000), showSymbol: false, showPaisa: false),
      '6,900',
    );
    expect(
      formatNpr(Paisa(690000), showSymbol: false, showPaisa: false),
      isNot(contains('रू')),
    );
  });
}
