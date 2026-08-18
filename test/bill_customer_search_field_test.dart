import 'dart:async';

import 'package:businesssajilo/core/l10n/app_localizations.dart';
import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/domain/models/customer.dart';
import 'package:businesssajilo/domain/models/member.dart';
import 'package:businesssajilo/domain/models/session_state.dart';
import 'package:businesssajilo/features/auth/providers/auth_provider.dart';
import 'package:businesssajilo/features/billing/bill_form_customer_field.dart';
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
  testWidgets('customer search keeps the field focused while results load', (
    tester,
  ) async {
    final gate = Completer<void>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(_OwnerAuth.new),
          customerListProvider.overrideWith((ref, query) async {
            await gate.future;
            return const [
              Customer(
                id: 'c1',
                businessId: 'biz',
                memberId: 'm1',
                shopName: 'Sagarmatha Traders',
              ),
            ];
          }),
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
            body: BillCustomerSearchField(onCustomerSelected: _noop),
          ),
        ),
      ),
    );
    await tester.pump();

    final field = find.byType(TextField);
    await tester.tap(field);
    await tester.pump();
    await tester.enterText(field, 'Sag');
    await tester.pump();

    expect(
      tester.widget<TextField>(field).focusNode?.hasFocus,
      isTrue,
      reason: 'typing must not unmount or unfocus the customer field',
    );
    expect(find.text('Sag'), findsOneWidget);

    gate.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(tester.widget<TextField>(field).focusNode?.hasFocus, isTrue);
  });
}

void _noop(Customer? _) {}
