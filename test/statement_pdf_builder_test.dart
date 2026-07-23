import 'package:businesssajilo/core/invoicing/pdf_fonts.dart';
import 'package:businesssajilo/core/invoicing/statement_document.dart';
import 'package:businesssajilo/core/invoicing/statement_pdf_builder.dart';
import 'package:businesssajilo/domain/models/business.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

StatementDocument _nepaliDoc() {
  return StatementDocument(
    business: const Business(
      id: 'biz1',
      name: 'राम स्टोर',
      phone: '9800000000',
      address: 'काठमाडौं',
    ),
    customerLabel: 'हरि बहादुर',
    fromDate: DateTime(2026, 1, 1),
    toDate: DateTime(2026, 1, 31),
    openingBalance: 0,
    closingBalance: 10000,
    lines: [
      StatementLine(
        date: DateTime(2026, 1, 15),
        description: 'बिल BS-0001',
        debit: 10000,
        credit: 0,
        balance: 10000,
      ),
    ],
    locale: const Locale('ne'),
    labels: const StatementLabels(
      title: 'ब्यालेन्स स्टेटमेन्ट',
      period: 'अवधि',
      customer: 'ग्राहक',
      date: 'मिति',
      description: 'विवरण',
      debit: 'डेबिट',
      credit: 'क्रेडिट',
      balance: 'बाँकी',
      openingBalance: 'सुरु बाँकी',
      closingBalance: 'अन्तिम बाँकी',
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(PdfFonts.clearCache);

  test('StatementPdfBuilder renders Nepali Unicode and em dash', () async {
    final bytes = await const StatementPdfBuilder().build(_nepaliDoc());
    expect(bytes, isNotEmpty);
    expect(bytes.length, greaterThan(100));
  });
}
