import 'package:businesssajilo/core/l10n/app_localizations.dart';
import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/domain/models/bill.dart';
import 'package:businesssajilo/domain/models/member.dart';
import 'package:businesssajilo/domain/models/session_state.dart';
import 'package:businesssajilo/features/auth/providers/auth_provider.dart';
import 'package:businesssajilo/features/billing/bill_detail_screen.dart';
import 'package:businesssajilo/features/billing/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _OwnerAuth extends AuthController {
  @override
  AsyncValue<SessionState> build() => const AsyncValue.data(
    SessionState(
      member: Member(
        id: 'owner-1',
        businessId: 'business-1',
        authUserId: 'auth-1',
        role: Role.owner,
        displayName: 'Owner',
      ),
    ),
  );
}

void main() {
  testWidgets('bill detail displays its reference note', (tester) async {
    const bill = Bill(
      id: 'bill-1',
      businessId: 'business-1',
      billNo: 'BS-0001',
      status: BillStatus.due,
      createdBy: 'owner-1',
      referenceNote: 'Deliver Friday afternoon',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(_OwnerAuth.new),
          billDetailProvider(bill.id).overrideWith((ref) async => bill),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BillDetailScreen(billId: 'bill-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('bill-reference-note')), findsOneWidget);
    expect(find.text('Reference note'), findsOneWidget);
    expect(find.text('Deliver Friday afternoon'), findsOneWidget);
  });

  testWidgets('bill detail displays Pay Bill button for due customer bill', (tester) async {
    const bill = Bill(
      id: 'bill-2',
      businessId: 'business-1',
      customerId: 'cust-1',
      customerShopName: 'Ram Store',
      billNo: 'BS-0002',
      status: BillStatus.due,
      grandTotal: 15000,
      createdBy: 'owner-1',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(_OwnerAuth.new),
          billDetailProvider(bill.id).overrideWith((ref) async => bill),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BillDetailScreen(billId: 'bill-2'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ram Store'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Record payment'), findsOneWidget);
  });

  testWidgets('bill detail customer name is clickable', (tester) async {
    const bill = Bill(
      id: 'bill-3',
      businessId: 'business-1',
      customerId: 'cust-1',
      customerShopName: 'Ram Store',
      billNo: 'BS-0003',
      status: BillStatus.paid,
      grandTotal: 15000,
      createdBy: 'owner-1',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(_OwnerAuth.new),
          billDetailProvider(bill.id).overrideWith((ref) async => bill),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BillDetailScreen(billId: 'bill-3'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final inkWell = find.widgetWithText(InkWell, 'Ram Store');
    expect(inkWell, findsOneWidget);
  });
}
