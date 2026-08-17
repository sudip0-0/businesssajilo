import 'package:businesssajilo/core/l10n/app_localizations.dart';
import 'package:businesssajilo/domain/models/session_state.dart';
import 'package:businesssajilo/features/auth/providers/auth_provider.dart';
import 'package:businesssajilo/web/auth/web_login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _UnauthenticatedAuth extends AuthController {
  @override
  AsyncValue<SessionState> build() => const AsyncValue.data(SessionState.empty);
}

void main() {
  testWidgets('web login fields expose password-manager autofill hints', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authProvider.overrideWith(_UnauthenticatedAuth.new)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: WebLoginPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(AutofillGroup), findsOneWidget);
    final fields = tester.widgetList<TextField>(find.byType(TextField));
    expect(
      fields.any(
        (f) => f.autofillHints?.contains(AutofillHints.username) == true,
      ),
      isTrue,
    );
    expect(
      fields.any(
        (f) => f.autofillHints?.contains(AutofillHints.password) == true,
      ),
      isTrue,
    );
  });
}
