import 'dart:ui' as ui;

import 'package:businesssajilo/app.dart';
import 'package:businesssajilo/core/l10n/app_localizations.dart';
import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/domain/models/member.dart';
import 'package:businesssajilo/domain/models/session_state.dart';
import 'package:businesssajilo/features/auth/providers/auth_provider.dart';
import 'package:businesssajilo/features/notifications/providers.dart';
import 'package:businesssajilo/web/layout/web_app_shell.dart';
import 'package:businesssajilo/web/layout/web_sidebar.dart';
import 'package:businesssajilo/web/theme/web_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Auth extends AuthController {
  @override
  AsyncValue<SessionState> build() => const AsyncValue.data(
    SessionState(
      member: Member(
        id: 'm',
        businessId: 'b',
        authUserId: 'u',
        role: Role.owner,
        displayName: 'Owner',
      ),
    ),
  );
}

void main() {
  testWidgets(
    'nested routes preserve shell semantics, keyboard navigation and locale controls',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.binding.setSurfaceSize(const Size(1440, 1000));
      final semantics = tester.ensureSemantics();
      final router = GoRouter(
        initialLocation: '/owner/dashboard',
        routes: [
          ShellRoute(
            builder: (context, state, child) {
              final l10n = AppLocalizations.of(context);
              return WebAppShell(
                navItems: [
                  WebNavItem(
                    label: l10n.dashboard,
                    path: '/owner/dashboard',
                    icon: Icons.dashboard,
                  ),
                  WebNavItem(
                    label: l10n.inventory,
                    path: '/owner/inventory',
                    icon: Icons.inventory,
                  ),
                ],
                child: child,
              );
            },
            routes: [
              for (final path in ['/owner/dashboard', '/owner/inventory'])
                GoRoute(
                  path: path,
                  builder: (context, state) => Scaffold(
                    body: TextButton(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) =>
                            const AlertDialog(content: Text('Modal content')),
                      ),
                      child: Text(state.uri.path),
                    ),
                  ),
                ),
            ],
          ),
        ],
      );
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith(_Auth.new),
              unreadNotificationCountProvider.overrideWith((ref) async => 0),
              notificationListProvider.overrideWith((ref) => Stream.value([])),
            ],
            child: Consumer(
              builder: (context, ref, _) => MaterialApp.router(
                routerConfig: router,
                theme: WebTheme.light(),
                locale: ref.watch(localeProvider),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        List<String> visibleLabels() => tester.semantics
            .simulatedAccessibilityTraversal()
            .map((node) => node.getSemanticsData().label)
            .toList();
        for (final label in ['Inventory', 'EN', 'NE', 'Notifications']) {
          expect(visibleLabels(), contains(label), reason: label);
          expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
          final node = tester.getSemantics(find.bySemanticsLabel(label));
          expect(
            node.getSemanticsData().hasAction(ui.SemanticsAction.tap),
            isTrue,
            reason: label,
          );
        }
        var focused = false;
        for (var i = 0; i < 20; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          focused =
              tester
                  .getSemantics(find.bySemanticsLabel('Inventory'))
                  .getSemanticsData()
                  .flagsCollection
                  .isFocused ==
              ui.Tristate.isTrue;
          if (focused) break;
        }
        expect(
          focused,
          isTrue,
          reason: 'Tab must reach the persistent sidebar',
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(
          router.routeInformationProvider.value.uri.path,
          '/owner/inventory',
        );
        expect(
          tester
              .getSemantics(find.bySemanticsLabel('Inventory'))
              .getSemanticsData()
              .flagsCollection
              .isSelected,
          ui.Tristate.isTrue,
        );
        final ne = tester.getSemantics(find.bySemanticsLabel('NE'));
        tester.binding.platformDispatcher.onSemanticsActionEvent!(
          ui.SemanticsActionEvent(
            nodeId: ne.id,
            viewId: tester.view.viewId,
            type: ui.SemanticsAction.tap,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('स्टक'), findsOneWidget);
        final en = tester.getSemantics(find.bySemanticsLabel('EN'));
        tester.binding.platformDispatcher.onSemanticsActionEvent!(
          ui.SemanticsActionEvent(
            nodeId: en.id,
            viewId: tester.view.viewId,
            type: ui.SemanticsAction.tap,
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('/owner/inventory'));
        await tester.pumpAndSettle();
        expect(
          visibleLabels(),
          isNot(contains('Inventory')),
          reason: 'Root modals must still exclude background controls',
        );
        router.pop();
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('Inventory'), findsOneWidget);
        await tester.tap(find.byTooltip('Collapse sidebar'));
        await tester.pumpAndSettle();
        expect(
          find.bySemanticsLabel('Inventory'),
          findsOneWidget,
          reason: 'Collapsed icon keeps its accessible name',
        );
        tester
            .state<TooltipState>(find.byTooltip('Notifications'))
            .ensureTooltipVisible();
        await tester.pumpAndSettle();
        final notificationLabels = tester.semantics
            .simulatedAccessibilityTraversal()
            .map((node) => node.getSemanticsData())
            .where(
              (data) =>
                  data.hasAction(ui.SemanticsAction.tap) &&
                  data.label.startsWith('Notifications'),
            )
            .map((data) => data.label)
            .toList();
        expect(
          notificationLabels,
          ['Notifications'],
          reason: 'Visible tooltips must not duplicate the button name',
        );
        Tooltip.dismissAllToolTips();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        semantics.dispose();
        router.dispose();
        await tester.binding.setSurfaceSize(null);
      }
    },
  );
}
