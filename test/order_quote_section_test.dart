import 'package:businesssajilo/core/l10n/app_localizations.dart';
import 'package:businesssajilo/data/repositories/quotes_repository.dart';
import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/domain/models/member.dart';
import 'package:businesssajilo/domain/models/quote.dart';
import 'package:businesssajilo/domain/models/quote_item.dart';
import 'package:businesssajilo/domain/models/session_state.dart';
import 'package:businesssajilo/features/auth/providers/auth_provider.dart';
import 'package:businesssajilo/features/quotes/order_quote_section.dart';
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

class _FakeQuotes extends QuotesRepository {
  _FakeQuotes(this.quotes) : super(null);

  final List<Quote> quotes;

  @override
  Future<List<Quote>> listForOrder(String orderId) async => quotes;
}

Quote _quote({
  required String id,
  required int version,
  required QuoteStatus status,
}) {
  return Quote(
    id: id,
    orderId: 'ord-1',
    version: version,
    status: status,
    total: 25000,
    createdBy: 'owner-1',
    createdAt: DateTime.now().toUtc().subtract(const Duration(days: 1)),
    items: [
      QuoteItem(
        id: 'qi-1',
        quoteId: id,
        productId: 'prod-1',
        qty: 5,
        rate: 5000,
        lineTotal: 25000,
        productName: 'Cola',
      ),
    ],
  );
}

Widget _wrap({
  required Role role,
  required List<Quote> quotes,
}) {
  final session = SessionState(
    member: Member(
      id: 'member-1',
      businessId: 'biz',
      authUserId: 'auth-1',
      role: role,
      displayName: 'Member',
    ),
  );
  return ProviderScope(
    overrides: [
      authProvider.overrideWith(() => _FixedAuth(session)),
      quotesRepositoryProvider.overrideWithValue(_FakeQuotes(quotes)),
    ],
    child: const MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: OrderQuoteSection(orderId: 'ord-1')),
    ),
  );
}

void main() {
  testWidgets('staff sees send-quote action when no quote exists', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(role: Role.owner, quotes: const []));
    await tester.pumpAndSettle();

    expect(find.text('Send quote'), findsOneWidget);
  });

  testWidgets('staff sees latest quote status and view action', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(role: Role.sales, quotes: [_quote(id: 'q-1', version: 1, status: QuoteStatus.sent)]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Quote sent'), findsOneWidget);
    expect(find.text('View quote'), findsOneWidget);
    // A pending quote means no duplicate send action.
    expect(find.text('Send quote'), findsNothing);
    expect(find.text('Send new quote'), findsNothing);
  });

  testWidgets('staff can requote after rejection', (tester) async {
    await tester.pumpWidget(
      _wrap(
        role: Role.owner,
        quotes: [_quote(id: 'q-1', version: 1, status: QuoteStatus.rejected)],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Quote rejected'), findsOneWidget);
    expect(find.text('Send new quote'), findsOneWidget);
  });

  testWidgets('customer sees respond action for pending quote', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(role: Role.customer, quotes: [_quote(id: 'q-1', version: 1, status: QuoteStatus.sent)]),
    );
    await tester.pumpAndSettle();

    expect(find.text('New quote received'), findsOneWidget);
    expect(find.text('Respond'), findsOneWidget);
  });

  testWidgets('customer sees nothing when no pending quote', (tester) async {
    await tester.pumpWidget(
      _wrap(
        role: Role.customer,
        quotes: [_quote(id: 'q-1', version: 1, status: QuoteStatus.accepted)],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Respond'), findsNothing);
    expect(find.text('View quote'), findsNothing);
  });
}
