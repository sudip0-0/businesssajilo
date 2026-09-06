import 'package:businesssajilo/core/l10n/app_localizations.dart';
import 'package:businesssajilo/data/local/app_database.dart';
import 'package:businesssajilo/data/sync/sync_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:businesssajilo/core/ui/sync_badge.dart';
import 'package:businesssajilo/data/sync/sync_providers.dart';
import 'package:businesssajilo/features/sync/sync_badge_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _UiDatabase extends Mock implements AppDatabase {}

class _UiSync extends Mock implements SyncService {}

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
  for (final locale in ['en', 'ne']) {
    for (final width in [360.0, 1000.0]) {
      testWidgets(
        'retained recovery is discoverable and guarded ($locale $width)',
        (tester) async {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final db = _UiDatabase();
          final sync = _UiSync();
          var retries = 0;
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                syncBundleProvider.overrideWithValue(
                  SyncBundle(
                    db: db,
                    sync: sync,
                    businessId: 'business',
                    memberId: 'member',
                    recoverPreviousWork: () async {
                      retries++;
                    },
                  ),
                ),
                syncQueueProvider.overrideWith((_) => Stream.value([])),
                syncStatusProvider.overrideWith(
                  (_) =>
                      Stream.value(const SyncStatus(state: SyncState.synced)),
                ),
                legacyRecoveryNoticeProvider.overrideWith(
                  (_) async => 'retained',
                ),
              ],
              child: MaterialApp(
                locale: Locale(locale),
                localizationsDelegates: _l10nDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: Scaffold(
                  appBar: AppBar(actions: const [SyncBadgeAction()]),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byIcon(Icons.history), findsOneWidget);
          await tester.tap(find.byIcon(Icons.history));
          await tester.pumpAndSettle();
          final l10n = AppLocalizations.of(
            tester.element(
              find.text(
                locale == 'en' ? 'Previous offline work' : 'पहिलेको अफलाइन काम',
              ),
            ),
          );
          expect(find.text(l10n.legacyRecoveryRetained), findsOneWidget);
          await tester.tap(find.text(l10n.legacyRecoveryRetry));
          await tester.pumpAndSettle();
          expect(retries, 1);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

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
