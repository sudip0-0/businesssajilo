import 'package:businesssajilo/core/l10n/app_localizations.dart';
import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/domain/models/customer.dart';
import 'package:businesssajilo/domain/models/member.dart';
import 'package:businesssajilo/domain/models/session_state.dart';
import 'package:businesssajilo/features/auth/providers/auth_provider.dart';
import 'package:businesssajilo/features/billing/bill_payment_sheet.dart';
import 'package:businesssajilo/features/customers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _OwnerAuth extends AuthController {
  @override
  AsyncValue<SessionState> build() => const AsyncValue.data(
    SessionState(
      member: Member(
        id: 'owner-1',
        businessId: 'biz',
        authUserId: 'auth-1',
        role: Role.owner,
        displayName: 'Owner',
      ),
    ),
  );
}

void main() {
  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [authProvider.overrideWith(_OwnerAuth.new)],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('bill payment sheet shows walk-in and paid options', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(const BillPaymentSheet(grandTotal: 10000, initialCustomerId: null)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Walk-in'), findsOneWidget);
    expect(find.text('Paid'), findsOneWidget);
  });

  testWidgets('bill payment sheet shows partial amount field', (tester) async {
    await tester.pumpWidget(wrap(const BillPaymentSheet(grandTotal: 10000)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Partial'));
    await tester.pumpAndSettle();

    expect(find.text('Amount paid'), findsOneWidget);
  });

  testWidgets('prefilled customer name shows in select customer field', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(_OwnerAuth.new),
          customerListProvider('').overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: BillPaymentSheet(
              grandTotal: 370000,
              initialCustomerId: 'cust-1',
              initialCustomerName: 'sudip',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('sudip'), findsOneWidget);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );
  });

  testWidgets('loads customer name by id when name not passed', (tester) async {
    const customer = Customer(
      id: 'cust-1',
      businessId: 'b1',
      memberId: 'm1',
      shopName: 'sudip',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(_OwnerAuth.new),
          customerListProvider('').overrideWith((ref) async => const []),
          customerDetailProvider(
            'cust-1',
          ).overrideWith((ref) async => customer),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: BillPaymentSheet(
              grandTotal: 370000,
              initialCustomerId: 'cust-1',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('sudip'), findsOneWidget);
  });
}
