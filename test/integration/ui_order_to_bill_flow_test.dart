import 'package:businesssajilo/core/l10n/app_localizations.dart';
import 'package:businesssajilo/data/repositories/bills_repository.dart';
import 'package:businesssajilo/data/repositories/orders_repository.dart';
import 'package:businesssajilo/data/repositories/products_repository.dart';
import 'package:businesssajilo/data/repositories/quotes_repository.dart';
import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/domain/models/bill.dart';
import 'package:businesssajilo/domain/models/catalog_product.dart';
import 'package:businesssajilo/domain/models/customer.dart';
import 'package:businesssajilo/domain/models/member.dart';
import 'package:businesssajilo/domain/models/order.dart';
import 'package:businesssajilo/domain/models/order_item.dart';
import 'package:businesssajilo/domain/models/product.dart';
import 'package:businesssajilo/domain/models/quote.dart';
import 'package:businesssajilo/domain/models/quote_item.dart';
import 'package:businesssajilo/domain/models/session_state.dart';
import 'package:businesssajilo/features/auth/providers/auth_provider.dart';
import 'package:businesssajilo/features/billing/bill_from_order_sheet.dart';
import 'package:businesssajilo/features/billing/bill_payment_sheet.dart';
import 'package:businesssajilo/features/billing/create_bill_from_order.dart';
import 'package:businesssajilo/features/customers/providers.dart';
import 'package:businesssajilo/features/orders/cart_sheet.dart';
import 'package:businesssajilo/features/quotes/quote_builder_screen.dart';
import 'package:businesssajilo/features/quotes/quote_detail_screen.dart';
import 'package:businesssajilo/web/features/billing/web_bill_form_content.dart';
import 'package:businesssajilo/web/features/billing/web_bill_form_line_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const customer = Customer(
  id: 'customer',
  businessId: 'business',
  memberId: 'customer-member',
  shopName: 'Retail shop',
);
const product = Product(
  id: 'product',
  businessId: 'business',
  name: 'Rice',
  unit: 'bag',
  referencePrice: 50055,
  stockCached: 100,
);

class _Auth extends AuthController {
  @override
  AsyncValue<SessionState> build() => AsyncData(_session(Role.customer));
  static SessionState _session(Role role) => SessionState(
    member: Member(
      id: '${role.name}-member',
      businessId: 'business',
      authUserId: role.name,
      role: role,
      displayName: role.name,
    ),
  );
  void asRole(Role role) => state = AsyncData(_session(role));
}

class _Orders implements OrdersRepository {
  Order? order;
  final placementIds = <String?>[];
  bool failAfterCommit = false;
  @override
  Future<Order> placeOrder({
    String? id,
    required String customerId,
    required List<OrderLineInput> lines,
    String? note,
  }) async {
    placementIds.add(id);
    order ??= Order(
      id: id!,
      businessId: 'business',
      customerId: customerId,
      status: OrderStatus.placed,
      customerNote: note,
      items: lines
          .map(
            (line) => OrderItem(
              id: 'item',
              orderId: id,
              productId: line.productId,
              qty: line.qty,
              productName: 'Rice',
            ),
          )
          .toList(),
    );
    if (failAfterCommit) {
      failAfterCommit = false;
      throw StateError('response lost');
    }
    return order!;
  }

  @override
  Future<Order> get(String id) async => order!;
  @override
  Future<BillingOrderDraft?> billingDraftFromOrder(String orderId) async =>
      null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Products implements ProductsRepository {
  bool fail = false;
  @override
  Future<Product> get(String id) async {
    if (fail) throw StateError('product lookup failed');
    return product;
  }

  @override
  Future<List<Product>> list({
    bool activeOnly = true,
    int offset = 0,
    int? limit,
    String? query,
    ProductStockFilter stockFilter = ProductStockFilter.all,
  }) async => [product];
  @override
  Future<String?> signedImageUrl(String? storagePath) async => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Quotes extends QuotesRepository {
  _Quotes() : super(null);
  final versions = <Quote>[];
  bool fail = false;
  int accepts = 0;
  @override
  Future<int?> lastQuotedRate({
    required String customerId,
    required String productId,
  }) async => null;
  @override
  Future<Quote> sendQuote({
    required String orderId,
    required String createdByMemberId,
    required int total,
    required List<QuoteLineInput> lines,
  }) async {
    for (var i = 0; i < versions.length; i++) {
      if (versions[i].status == QuoteStatus.sent) {
        versions[i] = versions[i].copyWith(status: QuoteStatus.superseded);
      }
    }
    final quote = Quote(
      id: 'quote-${versions.length + 1}',
      orderId: orderId,
      version: versions.length + 1,
      status: QuoteStatus.sent,
      createdBy: createdByMemberId,
      total: total,
      items: lines
          .map(
            (line) => QuoteItem(
              id: 'qi',
              quoteId: 'quote-${versions.length + 1}',
              productId: line.productId,
              productName: 'Rice',
              qty: line.qty,
              rate: line.rate,
              discount: line.discount,
              lineTotal: line.lineTotal,
            ),
          )
          .toList(),
    );
    versions.add(quote);
    return quote;
  }

  @override
  Future<Quote> get(String id) async =>
      versions.firstWhere((quote) => quote.id == id);
  @override
  Future<List<Quote>> listForOrder(String orderId) async =>
      versions.reversed.toList();
  @override
  Future<Quote?> latestAccepted(String orderId) async {
    if (fail) throw StateError('quote lookup failed');
    return versions
        .where((quote) => quote.status == QuoteStatus.accepted)
        .lastOrNull;
  }

  @override
  Future<Quote> accept(String quoteId, {String? comment}) async {
    accepts++;
    final i = versions.indexWhere((quote) => quote.id == quoteId);
    versions[i] = versions[i].copyWith(
      status: QuoteStatus.accepted,
      responseComment: comment,
    );
    return versions[i];
  }
}

class _Bills implements BillsRepository {
  _Bills(this.orders);
  final _Orders orders;
  List<BillLineInput>? savedLines;
  Bill? saved;
  @override
  Future<Bill> createFromOrder({
    required String orderId,
    required String customerId,
    required String createdByMemberId,
    required BillStatus status,
    required int itemsTotal,
    required int discount,
    required int grandTotal,
    required List<BillLineInput> lines,
    PaymentMethod paymentMethod = PaymentMethod.cash,
    String? paymentRefNote,
    int? paymentAmount,
  }) async {
    savedLines = lines;
    orders.order = orders.order!.copyWith(status: OrderStatus.billed);
    return saved = Bill(
      id: 'bill',
      billNo: 'BS-0001',
      businessId: 'business',
      orderId: orderId,
      customerId: customerId,
      createdBy: createdByMemberId,
      status: status,
      itemsTotal: itemsTotal,
      discount: discount,
      grandTotal: grandTotal,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Orders orders;
  late _Quotes quotes;
  late _Products products;
  late _Bills bills;
  late ProviderContainer container;
  setUp(() {
    orders = _Orders();
    quotes = _Quotes();
    products = _Products();
    bills = _Bills(orders);
    container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(_Auth.new),
        ordersRepositoryProvider.overrideWithValue(orders),
        quotesRepositoryProvider.overrideWithValue(quotes),
        productsRepositoryProvider.overrideWithValue(products),
        billsRepositoryProvider.overrideWithValue(bills),
        ownCustomerProvider.overrideWith((ref) async => customer),
        customerDetailProvider(
          customer.id,
        ).overrideWith((ref) async => customer),
        customerListProvider('').overrideWith((ref) async => [customer]),
      ],
    );
  });
  tearDown(() => container.dispose());

  Future<void> screen(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => Scaffold(body: child),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  Future<void> place(WidgetTester tester) async {
    await screen(
      tester,
      const CartSheet(
        products: [
          CatalogProduct(
            id: 'product',
            businessId: 'business',
            name: 'Rice',
            unit: 'bag',
          ),
        ],
        quantities: {'product': 2},
      ),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Place Order'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Place Order'),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> quote(WidgetTester tester, {required bool revised}) async {
    await screen(tester, QuoteBuilderScreen(orderId: orders.order!.id));
    if (revised) await tester.tap(find.byIcon(Icons.add));
    await tester.enterText(
      find.byType(TextFormField).at(0),
      revised ? '12.55' : '15.25',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      revised ? '0.25' : '0',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Send quote'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'deterministic screen integration: order → quote v1/v2 → customer accept → editable bill',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await place(tester);
      expect(orders.order!.items.single.qty, 2);
      expect(orders.placementIds.single, isNotEmpty);
      (container.read(authProvider.notifier) as _Auth).asRole(Role.owner);
      await quote(tester, revised: false);
      await quote(tester, revised: true);
      expect(quotes.versions.map((q) => q.version), [1, 2]);
      expect(quotes.versions.first.status, QuoteStatus.superseded);
      expect(quotes.versions.last.total, 3740);
      (container.read(authProvider.notifier) as _Auth).asRole(Role.customer);
      await screen(tester, QuoteDetailScreen(quoteId: quotes.versions.last.id));
      expect(find.textContaining('12.55'), findsOneWidget);
      final acceptButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Accept'),
      );
      acceptButton.onPressed!();
      acceptButton.onPressed!();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(FilledButton, 'Accept'),
        ),
      );
      await tester.pumpAndSettle();
      expect(quotes.accepts, 1);
      (container.read(authProvider.notifier) as _Auth).asRole(Role.owner);
      await screen(
        tester,
        BillFromOrderSheet(orderId: orders.order!.id, customerId: customer.id),
      );
      final fields = tester
          .widgetList<TextFormField>(find.byType(TextFormField))
          .toList();
      expect(fields.map((f) => f.initialValue), ['3', '12.55', '0.25']);
      expect(find.textContaining('37.40'), findsWidgets);
      final saveButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Save bill'),
      );
      saveButton.onPressed!();
      saveButton.onPressed!();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(BillPaymentSheet), findsOneWidget);
      await tester.tap(
        find
            .descendant(
              of: find.byType(BillPaymentSheet),
              matching: find.byType(FilledButton),
            )
            .last,
      );
      await tester.pumpAndSettle();
      expect(bills.saved!.customerId, customer.id);
      expect(bills.saved!.grandTotal, 3740);
      expect(bills.savedLines!.single.qty, 3);
      expect(bills.savedLines!.single.rate, 1255);
      expect(bills.savedLines!.single.discount, 25);
      expect(orders.order!.status, OrderStatus.billed);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('placement retry uses the same UUID after a lost response', (
    tester,
  ) async {
    orders.failAfterCommit = true;
    await place(tester);
    expect(orders.order, isNotNull);
    await tester.tap(find.widgetWithText(FilledButton, 'Place Order'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Place Order'),
      ),
    );
    await tester.pumpAndSettle();
    expect(orders.placementIds, hasLength(2));
    expect(orders.placementIds[0], orders.placementIds[1]);
  });

  for (final web in [false, true]) {
    testWidgets(
      '${web ? 'web' : 'mobile'} bill draft fails closed and retries quote/product lookup',
      (tester) async {
        tester.view.physicalSize = const Size(1440, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        orders.order = const Order(
          id: 'order',
          businessId: 'business',
          customerId: 'customer',
          status: OrderStatus.placed,
          items: [
            OrderItem(
              id: 'item',
              orderId: 'order',
              productId: 'product',
              qty: 2,
            ),
          ],
        );
        quotes.fail = true;
        final widget = web
            ? const WebBillFormContent(orderId: 'order')
            : const BillFromOrderSheet(
                orderId: 'order',
                customerId: 'customer',
              );
        await screen(tester, widget);
        expect(find.text('Try again'), findsOneWidget);
        expect(bills.saved, isNull);
        quotes.fail = false;
        products.fail = true;
        await tester.tap(find.text('Try again'));
        await tester.pumpAndSettle();
        expect(find.text('Try again'), findsOneWidget);
        products.fail = false;
        await tester.tap(find.text('Try again'));
        await tester.pumpAndSettle();
        expect(find.text('Try again'), findsNothing);
        expect(find.textContaining('500.55'), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'web accepted quote prefill preserves discount and changed qty through save',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      orders.order = const Order(
        id: 'order',
        businessId: 'business',
        customerId: 'customer',
        status: OrderStatus.placed,
        items: [
          OrderItem(id: 'item', orderId: 'order', productId: 'product', qty: 2),
        ],
      );
      final sent = await quotes.sendQuote(
        orderId: 'order',
        createdByMemberId: 'owner',
        total: 3740,
        lines: [
          const QuoteLineInput(
            productId: 'product',
            qty: 3,
            rate: 1255,
            discount: 25,
            lineTotal: 3740,
          ),
        ],
      );
      await quotes.accept(sent.id);
      (container.read(authProvider.notifier) as _Auth).asRole(Role.owner);
      final key = GlobalKey<WebBillFormContentState>();
      products.fail = true;
      await screen(tester, WebBillFormContent(key: key, orderId: 'order'));
      expect(find.text('Try again'), findsOneWidget);
      expect(find.byType(WebBillItemRow), findsNothing);
      products.fail = false;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      final row = tester.widget<WebBillItemRow>(find.byType(WebBillItemRow));
      expect(row.line.qty, 3);
      expect(row.line.rate, 1255);
      expect(row.line.discount, 25);
      expect(row.line.lineTotal, 3740);
      expect(find.text('12.55'), findsOneWidget);
      await key.currentState!.saveAsDue();
      await tester.pumpAndSettle();
      expect(bills.saved!.grandTotal, 3740);
      expect(bills.savedLines!.single.discount, 25);
      expect(bills.savedLines!.single.qty, 3);
      expect(bills.saved!.orderId, 'order');
    },
  );

  testWidgets(
    'quote draft lookup failure retries and duplicate send is guarded',
    (tester) async {
      orders.order = const Order(
        id: 'order',
        businessId: 'business',
        customerId: 'customer',
        status: OrderStatus.placed,
        items: [
          OrderItem(id: 'item', orderId: 'order', productId: 'product', qty: 2),
        ],
      );
      (container.read(authProvider.notifier) as _Auth).asRole(Role.owner);
      products.fail = true;
      await screen(tester, const QuoteBuilderScreen(orderId: 'order'));
      expect(find.text('Try again'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Send quote'), findsNothing);
      products.fail = false;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Send quote'),
      );
      button.onPressed!();
      button.onPressed!();
      await tester.pumpAndSettle();
      expect(quotes.versions, hasLength(1));
    },
  );

  test(
    'accepted quote mapping uses exact lines, not order quantities or reference prices',
    () async {
      orders.order = const Order(
        id: 'order',
        businessId: 'business',
        customerId: 'customer',
        status: OrderStatus.placed,
        items: [
          OrderItem(id: 'item', orderId: 'order', productId: 'product', qty: 2),
        ],
      );
      final sent = await quotes.sendQuote(
        orderId: 'order',
        createdByMemberId: 'owner',
        total: 3740,
        lines: [
          const QuoteLineInput(
            productId: 'product',
            qty: 3,
            rate: 1255,
            discount: 25,
            lineTotal: 3740,
          ),
        ],
      );
      await quotes.accept(sent.id);
      products.fail = true;
      final draft = await loadBillFromOrderRepositories(
        orderId: 'order',
        orders: orders,
        quotes: quotes,
        products: products,
      );
      expect(draft!.lines.single.qty, 3);
      expect(draft.lines.single.rate, 1255);
      expect(draft.lines.single.discount, 25);
      expect(draft.grandTotal, 3740);
    },
  );
}
