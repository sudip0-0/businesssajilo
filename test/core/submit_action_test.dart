import 'package:businesssajilo/core/errors/app_failure.dart';
import 'package:businesssajilo/core/l10n/app_localizations.dart';
import 'package:businesssajilo/core/ui/submit_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('runSubmitAction shows mapped permission message', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return FilledButton(
                onPressed: () {
                  runSubmitAction(
                    context,
                    action: () async {
                      throw const AppFailure.permission(
                        detail: 'You do not have permission for this action.',
                      );
                    },
                  );
                },
                child: const Text('Go'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Go'));
    await tester.pump(); // start snackbar
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.text('You do not have permission for this action.'),
      findsOneWidget,
    );
  });
}
