import 'package:businesssajilo/core/l10n/app_localizations.dart';
import 'package:businesssajilo/core/ui/sync_badge.dart';
import 'package:businesssajilo/data/sync/sync_providers.dart';
import 'package:businesssajilo/features/sync/sync_badge_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _l10nDelegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

Future<void> _pump(WidgetTester tester, {required SyncStatus status}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        syncStatusProvider.overrideWith((ref) => Stream.value(status)),
      ],
      child: MaterialApp(
        localizationsDelegates: _l10nDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(appBar: AppBar(actions: const [SyncBadgeAction()])),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('hides sync action when state is synced', (tester) async {
    await _pump(tester, status: const SyncStatus(state: SyncState.synced));

    expect(find.byType(IconButton), findsNothing);
    expect(find.byIcon(Icons.cloud_done), findsNothing);
    expect(find.byIcon(Icons.cloud_upload), findsNothing);
  });

  testWidgets('shows icon-only action when pending', (tester) async {
    await _pump(
      tester,
      status: const SyncStatus(state: SyncState.pending, pendingCount: 3),
    );

    expect(find.byIcon(Icons.cloud_upload), findsOneWidget);
    expect(find.textContaining('pending'), findsNothing);
  });
}
