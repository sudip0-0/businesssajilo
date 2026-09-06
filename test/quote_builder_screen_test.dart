import 'dart:typed_data';

import 'package:businesssajilo/core/errors/app_failure.dart';
import 'package:businesssajilo/core/l10n/app_localizations.dart';
import 'package:businesssajilo/core/utils/money.dart';
import 'package:businesssajilo/data/repositories/orders_repository.dart';
import 'package:businesssajilo/data/repositories/products_repository.dart';
import 'package:businesssajilo/data/repositories/quotes_repository.dart';
import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/domain/models/member.dart';
import 'package:businesssajilo/domain/models/order.dart';
import 'package:businesssajilo/domain/models/order_item.dart';
import 'package:businesssajilo/domain/models/product.dart';
import 'package:businesssajilo/domain/models/quote.dart';
import 'package:businesssajilo/domain/models/session_state.dart';
import 'package:businesssajilo/features/auth/providers/auth_provider.dart';
import 'package:businesssajilo/features/quotes/quote_builder_screen.dart';
import 'package:businesssajilo/web/theme/web_theme.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FixedAuth extends AuthController {
  _FixedAuth(this.session);
  final SessionState session;

  @override
  AsyncValue<SessionState> build() => AsyncValue.data(session);
}

class _FakeOrders implements OrdersRepository {
  _FakeOrders({
    this.items = const [
      OrderItem(
        id: 'oi-1',
        orderId: 'ord-1',
        productId: 'prod-1',
        qty: 2,
        productName: 'Cola',
      ),
    ],
  });

  final List<OrderItem> items;

  @override
  Future<Order> get(String id) async => Order(
    id: 'ord-1',
    businessId: 'biz',
    customerId: 'cust-1',
    status: OrderStatus.placed,
    items: items,
  );

  @override
  Future<List<Order>> listForStaff({
    List<OrderStatus>? statuses,
    int offset = 0,
    int? limit,
  }) async => const [];

  @override
  Future<List<Order>> listOwn({int offset = 0, int? limit}) async => const [];

  @override
  Future<int> pendingCount() async => 0;

  @override
  Future<int> ownOrderCount() async => 0;

  @override
  Future<Order> placeOrder({
    String? id,
    required String customerId,
    required List<OrderLineInput> lines,
    String? note,
  }) => throw UnimplementedError();

  @override
  Future<Order> updateStatus(String id, OrderStatus status) =>
      throw UnimplementedError();

  @override
  Future<BillingOrderDraft?> billingDraftFromOrder(String orderId) async =>
      null;
}

class _FakeProducts implements ProductsRepository {
  _FakeProducts({
    this.catalog = const [
      Product(
        id: 'prod-1',
        businessId: 'biz',
        name: 'Cola',
        referencePrice: 500,
      ),
    ],
  });

  final List<Product> catalog;

  @override
  Future<Product> get(String id) async =>
      catalog.firstWhere((p) => p.id == id, orElse: () => catalog.first);

  @override
  Future<List<Product>> list({
    bool activeOnly = true,
    int offset = 0,
    int? limit,
    String? query,
    ProductStockFilter stockFilter = ProductStockFilter.all,
  }) async => const [];

  @override
  Future<int> lowStockCount() async => 0;

  @override
  Future<List<Product>> listLowStock({int limit = 2}) async => const [];

  @override
  Future<Product> create({
    required String name,
    String? nameNp,
    String? sku,
    required String unit,
    int costPrice = 0,
    int referencePrice = 0,
    int lowStockThreshold = 0,
  }) => throw UnimplementedError();

  @override
  Future<Product> update({
    required String id,
    required String name,
    String? nameNp,
    String? sku,
    required String unit,
    int costPrice = 0,
    int referencePrice = 0,
    int lowStockThreshold = 0,
    String? imageUrl,
  }) => throw UnimplementedError();

  @override
  Future<void> deactivate(String id) => throw UnimplementedError();

  @override
  Future<void> activate(String id) => throw UnimplementedError();

  @override
  Future<String> uploadImage({
    required String businessId,
    required String productId,
    required Uint8List bytes,
    required String mimeType,
  }) => throw UnimplementedError();

  @override
  Future<String?> signedImageUrl(String? storagePath) async => null;
}

class _FailingQuotes extends QuotesRepository {
  _FailingQuotes({this.lastQuoted = 500}) : super(null);

  final int? lastQuoted;
  int sendCalls = 0;
  int? sentTotal;
  List<QuoteLineInput>? sentLines;

  @override
  Future<int?> lastQuotedRate({
    required String customerId,
    required String productId,
  }) async => lastQuoted;

  @override
  Future<Quote> sendQuote({
    required String orderId,
    required String createdByMemberId,
    required int total,
    required List<QuoteLineInput> lines,
  }) async {
    sendCalls++;
    sentTotal = total;
    sentLines = lines;
    throw const AppFailure.permission(detail: 'forbidden');
  }
}

void main() {
  const session = SessionState(
    member: Member(
      id: 'owner-1',
      businessId: 'biz',
      authUserId: 'auth-1',
      role: Role.owner,
      displayName: 'Owner',
    ),
  );

  Widget wrap({
    OrdersRepository? orders,
    ProductsRepository? products,
    QuotesRepository? quotes,
  }) {
    return ProviderScope(
      overrides: [
        authProvider.overrideWith(() => _FixedAuth(session)),
        ordersRepositoryProvider.overrideWithValue(orders ?? _FakeOrders()),
        productsRepositoryProvider.overrideWithValue(
          products ?? _FakeProducts(),
        ),
        quotesRepositoryProvider.overrideWithValue(quotes ?? _FailingQuotes()),
      ],
      child: MaterialApp(
        theme: kIsWeb ? WebTheme.light() : null,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const QuoteBuilderScreen(orderId: 'ord-1'),
      ),
    );
  }

  testWidgets('quote builder loads lines and updates totals on qty change', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Cola'), findsOneWidget);
    // 2 × 500 paisa = रू 10.00.
    expect(find.textContaining('Grand Total'), findsOneWidget);
    expect(find.textContaining('10'), findsWidgets);

    // QtyStepper + button increases qty → 3 × 500 = रू 15.
    final plus = find.byIcon(Icons.add);
    expect(plus, findsOneWidget);
    await tester.tap(plus);
    await tester.pumpAndSettle();

    expect(find.textContaining('15'), findsWidgets);
  });

  testWidgets('quote builder shows failure snackbar when send fails', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Send quote'));
    await tester.pumpAndSettle();

    expect(find.text('forbidden'), findsOneWidget);
  });

  testWidgets(
    'overflow qty keeps raw input, blocks send, and recovers quote terms',
    (tester) async {
      final quotes = _FailingQuotes(lastQuoted: null);
      await tester.pumpWidget(
        wrap(
          orders: _FakeOrders(
            items: const [
              OrderItem(
                id: 'oi-1',
                orderId: 'ord-1',
                productId: 'prod-1',
                qty: 1,
                productName: 'Cola',
              ),
            ],
          ),
          products: _FakeProducts(
            catalog: const [
              Product(
                id: 'prod-1',
                businessId: 'biz',
                name: 'Cola',
                referencePrice: maxExactPaisa,
              ),
            ],
          ),
          quotes: quotes,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Cola'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).last, '1.00');
      await tester.pump();
      expect(find.text('1.00'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('2'), findsWidgets);
      expect(find.text('Enter a valid number'), findsWidgets);
      expect(find.text('Discount cannot exceed the line amount'), findsNothing);

      await tester.tap(find.widgetWithText(FilledButton, 'Send quote'));
      await tester.pumpAndSettle();
      expect(quotes.sendCalls, 0);
      expect(find.text('forbidden'), findsNothing);
      expect(find.text('Enter a valid number'), findsWidgets);
      expect(find.text('1.00'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      expect(tester.takeException(), isNull);
      expect(find.text('Enter a valid number'), findsNothing);
      expect(find.text('1.00'), findsOneWidget);
      expect(
        find.textContaining(formatNpr(const Paisa(maxExactPaisa - 100))),
        findsWidgets,
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Send quote'));
      await tester.pumpAndSettle();
      expect(quotes.sendCalls, 1);
      expect(quotes.sentTotal, maxExactPaisa - 100);
      expect(quotes.sentLines, hasLength(1));
      expect(quotes.sentLines!.single.qty, 1);
      expect(quotes.sentLines!.single.rate, maxExactPaisa);
      expect(quotes.sentLines!.single.discount, 100);
      expect(find.text('forbidden'), findsOneWidget);
    },
  );

  testWidgets('combined quote totals overflow blocks send and recovers', (
    tester,
  ) async {
    final half = maxExactPaisa ~/ 2 + 1;
    final quotes = _FailingQuotes(lastQuoted: null);
    await tester.pumpWidget(
      wrap(
        orders: _FakeOrders(
          items: const [
            OrderItem(
              id: 'oi-1',
              orderId: 'ord-1',
              productId: 'prod-1',
              qty: 1,
              productName: 'Cola',
            ),
            OrderItem(
              id: 'oi-2',
              orderId: 'ord-1',
              productId: 'prod-2',
              qty: 1,
              productName: 'Fanta',
            ),
          ],
        ),
        products: _FakeProducts(
          catalog: [
            Product(
              id: 'prod-1',
              businessId: 'biz',
              name: 'Cola',
              referencePrice: half,
            ),
            Product(
              id: 'prod-2',
              businessId: 'biz',
              name: 'Fanta',
              referencePrice: half,
            ),
          ],
        ),
        quotes: quotes,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Cola'), findsOneWidget);
    expect(find.text('Fanta'), findsOneWidget);
    expect(
      find.textContaining('Grand Total: Enter a valid number'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Send quote'));
    await tester.pumpAndSettle();
    expect(quotes.sendCalls, 0);
    expect(find.text('forbidden'), findsNothing);
    expect(
      find.textContaining('Grand Total: Enter a valid number'),
      findsOneWidget,
    );

    final rateFields = find.byType(TextFormField);
    await tester.enterText(rateFields.at(2), '0');
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(
      find.textContaining('Grand Total: Enter a valid number'),
      findsNothing,
    );
    expect(
      find.textContaining('Grand Total: ${formatNpr(Paisa(half))}'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Send quote'));
    await tester.pumpAndSettle();
    expect(quotes.sendCalls, 1);
    expect(quotes.sentTotal, half);
    expect(quotes.sentLines, hasLength(2));
    expect(quotes.sentLines![0].rate, half);
    expect(quotes.sentLines![1].rate, 0);
    expect(find.text('forbidden'), findsOneWidget);
  });
}
