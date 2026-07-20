import 'package:businesssajilo/core/l10n/app_localizations.dart';
import 'package:businesssajilo/features/notifications/notification_bell_action.dart';
import 'package:businesssajilo/features/notifications/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('notification bell renders without badge when unread is zero', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationListProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: NotificationBellAction()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });

  testWidgets('notification bell opens dropdown panel', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationListProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(56),
              child: ColoredBox(
                color: Colors.white,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: NotificationBellAction(),
                ),
              ),
            ),
            body: SizedBox.expand(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsWidgets);
    expect(find.text('No notifications yet'), findsOneWidget);
    expect(find.text('Mark all read'), findsOneWidget);
  });
}
