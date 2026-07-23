import 'dart:typed_data';

import 'package:businesssajilo/core/errors/app_failure.dart';
import 'package:businesssajilo/core/l10n/app_localizations.dart';
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
  @override
  Future<Order> get(String id) async => const Order(
    id: 'ord-1',
    businessId: 'biz',
    customerId: 'cust-1',
    status: OrderStatus.placed,
    items: [
      OrderItem(
        id: 'oi-1',
        orderId: 'ord-1',
        productId: 'prod-1',
        qty: 2,
        productName: 'Cola',
      ),
    ],
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
  Future<List<Order>> fulfillmentQueue({int offset = 0, int? limit}) async =>
      const [];

  @override
  Future<int> pendingCount() async => 0;

  @override
  Future<int> openQuotesCount() async => 0;

  @override
  Future<int> ownOrderCount() async => 0;

  @override
  Future<int> fulfillmentActiveCount() async => 0;

  @override
  Future<Order> placeOrder({
    required String customerId,
    required List<OrderLineInput> lines,
    String? note,
  }) => throw UnimplementedError();

  @override
  Future<Order> updateStatus(String id, OrderStatus status) =>
      throw UnimplementedError();
}

class _FakeProducts implements ProductsRepository {
  @override
  Future<Product> get(String id) async => const Product(
    id: 'prod-1',
    businessId: 'biz',
    name: 'Cola',
    referencePrice: 500,
  );

  @override
  Future<List<Product>> list({
    bool activeOnly = true,
    int offset = 0,
    int? limit,
    String? query,
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
    String? categoryId,
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
    String? categoryId,
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
  _FailingQuotes() : super(null);

  @override
  Future<Quote> sendQuote({
    required String orderId,
    required String createdByMemberId,
    required int total,
    required List<QuoteLineInput> lines,
  }) async {
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

  Widget wrap() {
    return ProviderScope(
      overrides: [
        authProvider.overrideWith(() => _FixedAuth(session)),
        ordersRepositoryProvider.overrideWithValue(_FakeOrders()),
        productsRepositoryProvider.overrideWithValue(_FakeProducts()),
        quotesRepositoryProvider.overrideWithValue(_FailingQuotes()),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: QuoteBuilderScreen(orderId: 'ord-1'),
      ),
    );
  }

  testWidgets('quote builder loads lines and updates totals on qty change', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Cola'), findsOneWidget);
    // 2 × 500 paisa = रू 10 (showPaisa: false).
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
}
