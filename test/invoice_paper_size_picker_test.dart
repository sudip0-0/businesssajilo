import 'package:businesssajilo/core/invoicing/invoice_document.dart';
import 'package:businesssajilo/core/invoicing/invoice_document_factory.dart';
import 'package:businesssajilo/core/invoicing/invoice_export_service.dart';
import 'package:businesssajilo/data/repositories/customers_repository.dart';
import 'package:businesssajilo/data/repositories/payments_repository.dart';
import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/domain/models/bill.dart';
import 'package:businesssajilo/domain/models/business.dart';
import 'package:businesssajilo/domain/models/customer.dart';
import 'package:businesssajilo/features/auth/providers/auth_provider.dart';
import 'package:businesssajilo/features/billing/invoice_export_actions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:businesssajilo/core/invoicing/invoice_paper_size.dart';
import 'package:businesssajilo/core/l10n/app_localizations.dart';
import 'package:businesssajilo/features/billing/invoice_paper_size_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class _InvoiceCustomers implements CustomersRepository {
  final balanceRequests = <bool>[];

  @override
  Future<Customer> get(String id, {bool includeBalances = true}) async {
    balanceRequests.add(includeBalances);
    if (includeBalances) throw StateError('financial access unavailable');
    return Customer(
      id: id,
      businessId: 'biz',
      memberId: 'customer-member',
      shopName: 'Shop',
      address: ' Kathmandu ',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _InvoicePayments implements PaymentsRepository {
  final billIds = <String>[];

  @override
  Future<int> totalReceivedForBill(String billId) async {
    billIds.add(billId);
    return 400;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _InvoicePrinter extends InvoiceExportService {
  InvoiceDocument? document;

  @override
  Future<void> printPdf(
    InvoiceDocument doc, {
    InvoicePaperSize paperSize = InvoicePaperSize.a4,
  }) async {
    document = doc;
  }
}

void main() {
  Widget wrap(Widget home) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );
  }

  for (final status in [BillStatus.due, BillStatus.partial]) {
    testWidgets(
      'invoice print loads identity only and preserves $status payment handling',
      (tester) async {
        final customers = _InvoiceCustomers();
        final payments = _InvoicePayments();
        final printer = _InvoicePrinter();
        final bill = Bill(
          id: 'bill',
          businessId: 'biz',
          billNo: 'BS-0001',
          customerId: 'customer',
          createdBy: 'staff',
          status: status,
          grandTotal: 1000,
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              customersRepositoryProvider.overrideWithValue(customers),
              paymentsRepositoryProvider.overrideWithValue(payments),
              invoiceExportServiceProvider.overrideWithValue(printer),
              currentBusinessProvider.overrideWith(
                (ref) async => const Business(id: 'biz', name: 'Business'),
              ),
            ],
            child: wrap(
              Scaffold(
                body: Consumer(
                  builder: (context, ref, _) => TextButton(
                    onPressed: () => exportBillPrint(ref, context, bill),
                    child: const Text('print'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('print'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('A4'));
        await tester.pumpAndSettle();

        expect(customers.balanceRequests, [false]);
        expect(printer.document?.customerAddress, 'Kathmandu');
        expect(
          printer.document?.amountReceived,
          status == BillStatus.partial ? 400 : null,
        );
        expect(
          payments.billIds,
          status == BillStatus.partial ? ['bill'] : isEmpty,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('paper size picker returns A4 when tapped', (tester) async {
    InvoicePaperSize? picked;
    await tester.pumpWidget(
      wrap(
        Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  picked = await showInvoicePaperSizePicker(
                    context,
                    title: 'Copy bill as image',
                  );
                },
                child: const Text('open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('A4'), findsOneWidget);
    expect(find.text('A5'), findsOneWidget);

    await tester.tap(find.text('A4'));
    await tester.pumpAndSettle();

    expect(picked, InvoicePaperSize.a4);
  });

  testWidgets('paper size picker runs onSelected before closing', (
    tester,
  ) async {
    InvoicePaperSize? selected;
    await tester.pumpWidget(
      wrap(
        Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () {
                  showInvoicePaperSizePicker(
                    context,
                    title: 'Copy bill as image',
                    onSelected: (size) async {
                      selected = size;
                    },
                  );
                },
                child: const Text('open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('A5'));
    await tester.pumpAndSettle();

    expect(selected, InvoicePaperSize.a5);
    expect(find.text('A5'), findsNothing);
  });
}
