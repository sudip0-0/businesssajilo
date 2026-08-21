import 'package:businesssajilo/core/l10n/app_localizations.dart';
import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/domain/models/member.dart';
import 'package:businesssajilo/domain/models/session_state.dart';
import 'package:businesssajilo/features/auth/providers/auth_provider.dart';
import 'package:businesssajilo/features/billing/bill_form_screen.dart';
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
  testWidgets('empty bill pins totals and hides payment status until save', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(_OwnerAuth.new),
          customerListProvider.overrideWith((ref, query) async => const []),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: BillFormScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Subtotal'), findsOneWidget);
    expect(find.text('Bill discount'), findsOneWidget);
    expect(find.text('Grand Total'), findsOneWidget);
    expect(find.text('Payment status'), findsNothing);
    expect(find.text('Paid'), findsNothing);
    expect(find.text('Cash'), findsNothing);
  });

  testWidgets('customer search hides bill totals until selection closes it', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(_OwnerAuth.new),
          customerListProvider.overrideWith((ref, query) async => const []),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: BillFormScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField).first);
    await tester.pump();

    expect(find.text('Subtotal'), findsNothing);
    expect(find.text('Bill discount'), findsNothing);
    expect(find.text('Grand Total'), findsNothing);

    await tester.tap(find.widgetWithText(ListTile, 'Walk-in Customer'));
    await tester.pump();

    expect(find.text('Subtotal'), findsOneWidget);
    expect(find.text('Bill discount'), findsOneWidget);
    expect(find.text('Grand Total'), findsOneWidget);
  });
}
