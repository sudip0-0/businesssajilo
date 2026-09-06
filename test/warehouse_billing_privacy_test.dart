import 'dart:async';

import 'package:businesssajilo/core/l10n/app_localizations.dart';
import 'package:businesssajilo/core/theme/app_theme.dart';
import 'package:businesssajilo/core/ui/adaptive_sheet.dart';
import 'package:businesssajilo/core/utils/money.dart';
import 'package:businesssajilo/data/repositories/bills_repository.dart';
import 'package:businesssajilo/data/repositories/customers_repository.dart';
import 'package:businesssajilo/data/repositories/payments_repository.dart';
import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/domain/models/bill.dart';
import 'package:businesssajilo/domain/models/customer.dart';
import 'package:businesssajilo/domain/models/member.dart';
import 'package:businesssajilo/domain/models/product.dart';
import 'package:businesssajilo/domain/models/session_state.dart';
import 'package:businesssajilo/features/auth/providers/auth_provider.dart';
import 'package:businesssajilo/features/billing/bill_form_customer_field.dart';
import 'package:businesssajilo/features/billing/bill_payment_sheet.dart';
import 'package:businesssajilo/features/inventory/providers.dart';
import 'package:businesssajilo/features/customers/providers.dart'
    as customer_providers;
import 'package:businesssajilo/web/features/billing/web_bill_form_content.dart';
import 'package:businesssajilo/web/theme/web_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _customer = Customer(
  id: 'customer-privacy',
  businessId: 'business-privacy',
  memberId: 'customer-member',
  shopName: 'Sagarmatha Traders',
  contactName: 'Sita Shrestha',
  phone: '9841000001',
  openingBalance: 87654300,
  balanceDue: 98765400,
);

const _product = Product(
  id: 'product-privacy',
  businessId: 'business-privacy',
  name: 'Rice bag',
  referencePrice: 125000,
  stockCached: 20,
);

class _WarehouseAuth extends AuthController {
  @override
  AsyncValue<SessionState> build() => const AsyncValue.data(
    SessionState(
      member: Member(
        id: 'warehouse-member',
        businessId: 'business-privacy',
        authUserId: 'warehouse-auth',
        role: Role.warehouse,
        displayName: 'Warehouse',
      ),
    ),
  );
}

class _DirectoryRepository implements CustomersRepository {
  _DirectoryRepository({this.pendingRead});
  final Future<Customer>? pendingRead;
  final listCalls = <({String? query, bool includeBalances})>[];
  final getCalls = <({String id, bool includeBalances})>[];
  final unexpectedCalls = <Symbol>[];

  @override
  Future<List<Customer>> list({
    int offset = 0,
    int? limit,
    String? query,
    bool includeBalances = true,
    CustomerBalanceFilter balanceFilter = CustomerBalanceFilter.all,
  }) async {
    listCalls.add((query: query, includeBalances: includeBalances));
    return query == null ||
            _customer.shopName.toLowerCase().contains(query.toLowerCase())
        ? [_customer]
        : [];
  }

  @override
  Future<Customer> get(String id, {bool includeBalances = true}) async {
    getCalls.add((id: id, includeBalances: includeBalances));
    // Live frames may call the repository outside the widget-test guard zone.
    // Keep the same strict input contract without calling a guarded test API here;
    // the test body also asserts the complete id/includeBalances call record.
    if (id != _customer.id) throw StateError('Unexpected customer id: $id');
    if (pendingRead != null) return await pendingRead!;
    return _customer;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    unexpectedCalls.add(invocation.memberName);
    throw StateError('Unexpected customer operation: ${invocation.memberName}');
  }
}

class _NoPaymentsRepository implements PaymentsRepository {
  final calls = <Symbol>[];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls.add(invocation.memberName);
    throw StateError('Warehouse requested payments: ${invocation.memberName}');
  }
}

class _RecordingBillsRepository implements BillsRepository {
  final submissions =
      <
        ({
          Bill bill,
          List<BillLineInput> lines,
          int? paymentAmount,
          PaymentMethod paymentMethod,
          String? guestName,
        })
      >[];

  @override
  Future<Bill> create({
    required String createdByMemberId,
    String? customerId,
    String? guestName,
    required BillStatus status,
    required int itemsTotal,
    required int discount,
    required int grandTotal,
    required List<BillLineInput> lines,
    PaymentMethod paymentMethod = PaymentMethod.cash,
    String? paymentRefNote,
    int? paymentAmount,
  }) async {
    final bill = Bill(
      id: 'saved-bill',
      businessId: 'business-privacy',
      billNo: 'BS-0001',
      customerId: customerId,
      createdBy: createdByMemberId,
      status: status,
      itemsTotal: itemsTotal,
      discount: discount,
      grandTotal: grandTotal,
      referenceNote: paymentRefNote,
    );
    submissions.add((
      bill: bill,
      lines: lines,
      paymentAmount: paymentAmount,
      paymentMethod: paymentMethod,
      guestName: guestName,
    ));
    return bill;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected bill operation: ${invocation.memberName}');
}

Widget _app({
  required Locale locale,
  required _DirectoryRepository directory,
  required _NoPaymentsRepository payments,
  required Widget home,
  _RecordingBillsRepository? bills,
  bool web = false,
}) => ProviderScope(
  // Live browser cases share an engine, but must not reuse another case's routes.
  key: UniqueKey(),
  overrides: [
    authProvider.overrideWith(_WarehouseAuth.new),
    customersRepositoryProvider.overrideWithValue(directory),
    paymentsRepositoryProvider.overrideWithValue(payments),
    if (bills != null) billsRepositoryProvider.overrideWithValue(bills),
    productListProvider.overrideWith((ref, query) async => [_product]),
  ],
  child: MaterialApp(
    locale: locale,
    theme: web ? WebTheme.light() : AppTheme.light(),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  ),
);

void _setSize(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void _expectPrivate(AppLocalizations l10n) {
  for (final label in [
    l10n.openingBalance,
    l10n.currentBalance,
    l10n.runningBalance,
    l10n.balance,
    l10n.ledger,
    l10n.totalDues,
    l10n.payments,
    l10n.paymentMethod,
    l10n.paymentAmount,
    l10n.amountPaid,
    l10n.paymentMethodCash,
    l10n.paymentMethodCheque,
    l10n.paymentMethodWallet,
    l10n.paymentMethodBank,
    l10n.partial,
  ]) {
    final allowedDueLabels = label == l10n.due
        ? find
              .descendant(
                of: find.byType(SegmentedButton<BillStatus>),
                matching: find.text(l10n.due),
              )
              .evaluate()
              .length
        : 0;
    expect(
      find.text(label),
      findsNWidgets(allowedDueLabels),
      reason:
          'Warehouse must not see financial label $label outside bill status',
    );
  }
  for (final value in [_customer.openingBalance, _customer.balanceDue]) {
    for (final text in [
      value.toString(),
      formatNpr(Paisa(value), showSymbol: false, showPaisa: false),
      formatNpr(Paisa(value), showSymbol: false),
    ]) {
      expect(
        find.textContaining(text),
        findsNothing,
        reason: 'Customer financial value leaked: $text',
      );
    }
  }
}

void _expectDueOnly(WidgetTester tester, AppLocalizations l10n) {
  _expectPrivate(l10n);
  expect(find.text(l10n.paid), findsNothing);
  final status = tester.widget<SegmentedButton<BillStatus>>(
    find.byType(SegmentedButton<BillStatus>),
  );
  expect(status.segments.map((segment) => segment.value), [BillStatus.due]);
  expect(status.selected, {BillStatus.due});
}

void _expectDirectoryOnly(
  _DirectoryRepository directory,
  _NoPaymentsRepository payments,
) {
  expect(directory.listCalls, isNotEmpty);
  expect(directory.listCalls.every((call) => !call.includeBalances), isTrue);
  expect(directory.getCalls.every((call) => !call.includeBalances), isTrue);
  expect(directory.unexpectedCalls, isEmpty);
  expect(payments.calls, isEmpty);
}

Finder _customerField() => find.descendant(
  of: find.byType(BillCustomerSearchField),
  matching: find.byType(TextField),
);

Future<void> _saveSheet(WidgetTester tester, AppLocalizations l10n) async {
  final save = find.widgetWithText(FilledButton, l10n.saveBill).last;
  await tester.ensureVisible(save);
  await tester.tap(save);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'late customer prefill cannot restore a cancelled customer selection',
    (tester) async {
      final pending = Completer<Customer>();
      final directory = _DirectoryRepository(pendingRead: pending.future);
      final payments = _NoPaymentsRepository();
      await tester.pumpWidget(
        _app(
          locale: const Locale('en'),
          directory: directory,
          payments: payments,
          home: Scaffold(
            body: BillPaymentSheet(
              grandTotal: 125029,
              initialCustomerId: _customer.id,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(directory.getCalls, [(id: _customer.id, includeBalances: false)]);
      expect(find.text(_customer.shopName), findsNothing);
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      pending.complete(_customer);
      await tester.pumpAndSettle();
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isTrue,
      );
      expect(find.byType(BillCustomerSearchField), findsNothing);
      expect(find.text(_customer.shopName), findsNothing);
      expect(payments.calls, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  for (final locale in [const Locale('en'), const Locale('ne')]) {
    for (final viewport in {
      'phone': const Size(390, 844),
      'desktop': const Size(1440, 1000),
    }.entries) {
      final variant = '${locale.languageCode} ${viewport.key}';

      testWidgets(
        'warehouse selects customer and returns due-only bill $variant',
        (tester) async {
          _setSize(tester, viewport.value);
          final directory = _DirectoryRepository();
          final payments = _NoPaymentsRepository();
          BillPaymentResult? result;
          await tester.pumpWidget(
            _app(
              locale: locale,
              directory: directory,
              payments: payments,
              home: Builder(
                builder: (context) => Scaffold(
                  body: FilledButton(
                    onPressed: () async {
                      result = await showAdaptiveSheet<BillPaymentResult>(
                        context: context,
                        title: AppLocalizations.of(context).saveBill,
                        child: const BillPaymentSheet(grandTotal: 125000),
                      );
                    },
                    child: Text(AppLocalizations.of(context).reviewAndSave),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byType(FilledButton));
          await tester.pumpAndSettle();
          final l10n = AppLocalizations.of(
            tester.element(find.byType(BillPaymentSheet)),
          );
          await tester.tap(find.byType(SwitchListTile));
          await tester.pumpAndSettle();
          _expectDueOnly(tester, l10n);

          expect(result, isNull);
          await tester.ensureVisible(_customerField());
          await tester.enterText(_customerField(), 'Sag');
          await tester.pump(const Duration(milliseconds: 350));
          await tester.pumpAndSettle();
          expect(find.text(_customer.phone!), findsOneWidget);
          _expectDueOnly(tester, l10n);
          await tester.ensureVisible(
            find.widgetWithText(ListTile, _customer.shopName),
          );
          await tester.tap(find.widgetWithText(ListTile, _customer.shopName));
          await tester.pumpAndSettle();
          expect(find.text(_customer.shopName), findsOneWidget);
          _expectDueOnly(tester, l10n);
          await tester.enterText(find.byType(TextFormField), '  Dispatch 42  ');
          await _saveSheet(tester, l10n);

          expect(result, isNotNull);
          expect(result!.status, BillStatus.due);
          expect(result!.customerId, _customer.id);
          expect(result!.guestName, isNull);
          expect(result!.paymentAmount, isNull);
          expect(result!.paymentRefNote, 'Dispatch 42');
          expect(find.byType(BillPaymentSheet), findsNothing);
          expect(
            directory.listCalls.any((call) => call.query == 'Sag'),
            isTrue,
          );
          _expectDirectoryOnly(directory, payments);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'warehouse prefilled customer lookup excludes balances $variant',
        (tester) async {
          _setSize(tester, viewport.value);
          final directory = _DirectoryRepository();
          final payments = _NoPaymentsRepository();
          await tester.pumpWidget(
            _app(
              locale: locale,
              directory: directory,
              payments: payments,
              home: Scaffold(
                body: BillPaymentSheet(
                  grandTotal: 125000,
                  initialCustomerId: _customer.id,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final l10n = AppLocalizations.of(
            tester.element(find.byType(BillPaymentSheet)),
          );
          expect(
            find.text(_customer.shopName),
            findsOneWidget,
            reason:
                'Prefill reads: ${directory.getCalls}; selected name: ${tester.widget<BillCustomerSearchField>(find.byType(BillCustomerSearchField)).selectedName}; provider: ${ProviderScope.containerOf(tester.element(find.byType(BillPaymentSheet))).read(customer_providers.customerDetailProvider(_customer.id))}',
          );
          expect(
            tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
            isFalse,
          );
          _expectDueOnly(tester, l10n);
          expect(directory.getCalls, [
            (id: _customer.id, includeBalances: false),
          ]);
          _expectDirectoryOnly(directory, payments);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'warehouse web form selects customer and persists due bill '
        '${locale.languageCode} ${viewport.key == 'phone' ? 'compact' : 'desktop'}',
        (tester) async {
          _setSize(tester, viewport.value);
          final directory = _DirectoryRepository();
          final payments = _NoPaymentsRepository();
          final bills = _RecordingBillsRepository();
          final formKey = GlobalKey<WebBillFormContentState>();
          var savedCount = 0;
          await tester.pumpWidget(
            _app(
              locale: locale,
              directory: directory,
              payments: payments,
              bills: bills,
              web: true,
              home: Builder(
                builder: (context) => Scaffold(
                  body: WebBillFormContent(
                    key: formKey,
                    onSaved: () => savedCount++,
                  ),
                  bottomNavigationBar: FilledButton(
                    onPressed: () => formKey.currentState!.saveBill(),
                    child: Text(AppLocalizations.of(context).saveBill),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final l10n = AppLocalizations.of(
            tester.element(find.byType(WebBillFormContent)),
          );
          final customerSearch = find.byWidgetPredicate(
            (widget) =>
                widget is TextField &&
                widget.decoration?.hintText == l10n.walkInCustomer,
          );
          await tester.ensureVisible(customerSearch);
          await tester.enterText(customerSearch, 'Sag');
          await tester.pump(const Duration(milliseconds: 350));
          await tester.pumpAndSettle();
          expect(find.text(_customer.shopName), findsOneWidget);
          expect(find.text(_customer.contactName!), findsOneWidget);
          _expectPrivate(l10n);
          await tester.tap(find.text(_customer.shopName));
          await tester.pumpAndSettle();
          expect(find.text(_customer.shopName), findsOneWidget);
          _expectPrivate(l10n);

          final productSearch = find.byWidgetPredicate(
            (widget) =>
                widget is TextField &&
                widget.decoration?.hintText == l10n.filterProducts,
          );
          await tester.ensureVisible(productSearch);
          await tester.enterText(productSearch, 'Rice');
          await tester.pump(const Duration(milliseconds: 350));
          await tester.pumpAndSettle();
          await tester.tap(find.text(_product.name));
          await tester.pumpAndSettle();
          expect(find.text(_product.name), findsOneWidget);
          expect(bills.submissions, isEmpty);
          await tester.tap(find.widgetWithText(FilledButton, l10n.saveBill));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          expect(find.byType(BillPaymentSheet), findsOneWidget);
          _expectDueOnly(tester, l10n);
          await tester.enterText(
            find.descendant(
              of: find.byType(BillPaymentSheet),
              matching: find.byType(TextFormField),
            ),
            'Warehouse dispatch',
          );
          await _saveSheet(tester, l10n);

          expect(savedCount, 1);
          expect(bills.submissions, hasLength(1));
          final submission = bills.submissions.single;
          expect(submission.bill.customerId, _customer.id);
          expect(submission.bill.createdBy, 'warehouse-member');
          expect(submission.bill.status, BillStatus.due);
          expect(submission.bill.itemsTotal, 125000);
          expect(submission.bill.discount, 0);
          expect(submission.bill.grandTotal, 125000);
          expect(submission.bill.referenceNote, 'Warehouse dispatch');
          expect(submission.paymentAmount, isNull);
          expect(submission.guestName, isNull);
          expect(submission.lines, hasLength(1));
          expect(submission.lines.single.productId, _product.id);
          expect(submission.lines.single.qty, 1);
          expect(submission.lines.single.rate, 125000);
          expect(submission.lines.single.lineTotal, 125000);
          expect(find.byType(BillPaymentSheet), findsNothing);
          expect(find.text(l10n.billSaved), findsOneWidget);
          _expectPrivate(l10n);
          expect(
            directory.listCalls.any((call) => call.query == 'sag'),
            isTrue,
          );
          _expectDirectoryOnly(directory, payments);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
