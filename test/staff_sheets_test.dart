import 'package:businesssajilo/core/errors/app_failure.dart';
import 'package:businesssajilo/core/l10n/app_localizations.dart';
import 'package:businesssajilo/data/repositories/members_repository.dart';
import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/domain/models/member.dart';
import 'package:businesssajilo/features/staff/add_member_sheet.dart';
import 'package:businesssajilo/features/staff/reset_member_password_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {List<dynamic> overrides = const []}) {
  return ProviderScope(
    overrides: overrides.cast(),
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

class _FailingMembers extends MembersRepository {
  _FailingMembers();

  @override
  Future<List<Member>> listMembers() =>
      throw UnimplementedError();

  @override
  Future<void> deactivateMember(String memberId) =>
      throw UnimplementedError();

  @override
  Future<void> activateMember(String memberId) =>
      throw UnimplementedError();

  @override
  Future<Member?> getMember(String memberId) =>
      throw UnimplementedError();

  @override
  Future<({String memberId, String? customerId})> createMember({
    String? email,
    required String password,
    required Role role,
    required String displayName,
    String? phone,
    String? shopName,
    String? contactName,
    String? address,
    int openingBalance = 0,
    bool isActive = true,
  }) async {
    throw const AppFailure.permission(detail: 'forbidden');
  }

  @override
  Future<void> resetMemberPassword({
    required String memberId,
    required String newPassword,
  }) async {
    throw const AppFailure.permission(detail: 'forbidden');
  }
}

Finder _field(String label) => find.widgetWithText(TextFormField, label);

void main() {
  testWidgets('add member sheet requires display name and password', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const AddMemberSheet()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('This field is required'), findsWidgets);
  });

  testWidgets('add member sheet shows mapped failure on create error', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const AddMemberSheet(),
        overrides: [
          membersRepositoryProvider.overrideWithValue(_FailingMembers()),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(_field('Your name'), 'Sales One');
    await tester.enterText(_field('Email'), 'sales@test.com');
    await tester.enterText(_field('Password'), 'password123');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('forbidden'), findsOneWidget);
  });

  testWidgets('reset password sheet rejects short passwords', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const ResetMemberPasswordSheet(memberId: 'm1', memberName: 'Sales One'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(_field('Temporary password'), 'short');
    await tester.tap(find.text('Reset password'));
    await tester.pumpAndSettle();

    expect(find.text('Password must be at least 8 characters'), findsOneWidget);
  });

  testWidgets('reset password sheet surfaces failure message', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const ResetMemberPasswordSheet(memberId: 'm1', memberName: 'Sales One'),
        overrides: [
          membersRepositoryProvider.overrideWithValue(_FailingMembers()),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(_field('Temporary password'), 'password123');
    await tester.tap(find.text('Reset password'));
    await tester.pumpAndSettle();

    expect(find.text('forbidden'), findsOneWidget);
    expect(find.text('Reset password'), findsOneWidget);
  });
}
