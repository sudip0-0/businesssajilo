import 'package:businesssajilo/core/l10n/app_localizations.dart';
import 'package:businesssajilo/features/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  testWidgets('login shows validation when fields empty', (tester) async {
    await tester.pumpWidget(_wrap(const LoginScreen()));

    expect(find.text('Sign in'), findsOneWidget);

    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(find.text('This field is required'), findsWidgets);
  });
}
