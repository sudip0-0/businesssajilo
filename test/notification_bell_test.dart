import 'dart:async';

import 'package:businesssajilo/core/l10n/app_localizations.dart';
import 'package:businesssajilo/data/repositories/notifications_repository.dart';
import 'package:businesssajilo/domain/models/notification_item.dart';
import 'package:businesssajilo/features/notifications/notification_bell_action.dart';
import 'package:businesssajilo/features/notifications/providers.dart';
import 'package:businesssajilo/features/notifications/notification_dropdown.dart';
import 'package:businesssajilo/web/theme/web_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeNotificationsRepository implements NotificationsRepository {
  _FakeNotificationsRepository(this._items);

  List<NotificationItem> _items;
  final _controller = StreamController<List<NotificationItem>>.broadcast();

  @override
  Future<List<NotificationItem>> list({int offset = 0, int limit = 30}) async =>
      _items.skip(offset).take(limit).toList();

  @override
  Stream<List<NotificationItem>> watch({int limit = 50}) async* {
    yield _items.take(limit).toList();
    yield* _controller.stream;
  }

  @override
  Future<int> unreadCount({Iterable<String> excludedTypes = const []}) async {
    return _items
        .where((item) => item.isUnread && !excludedTypes.contains(item.type))
        .length;
  }

  @override
  Future<void> markRead(String id) async {
    _items = [
      for (final item in _items)
        if (item.id == id)
          item.copyWith(readAt: DateTime.now().toUtc())
        else
          item,
    ];
    _controller.add(_items);
  }

  @override
  Future<void> markAllRead() async {
    final now = DateTime.now().toUtc();
    _items = [
      for (final item in _items)
        item.isUnread ? item.copyWith(readAt: now) : item,
    ];
    _controller.add(_items);
  }
}

NotificationItem _unreadItem() => NotificationItem(
  id: 'n1',
  businessId: 'b1',
  recipientMemberId: 'm1',
  type: 'low_stock',
  payload: const {},
  createdAt: DateTime.utc(2026, 1, 1),
);

const _l10nDelegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

void main() {
  for (final size in [const Size(320, 260), const Size(1440, 260)]) {
    testWidgets(
      'notification dropdown fits $size and restores focus after Escape',
      (tester) async {
        await tester.binding.setSurfaceSize(size);
        final trigger = FocusNode();
        final key = GlobalKey();
        var viewAllCalls = 0;
        try {
          await tester.pumpWidget(
            ProviderScope(
              key: UniqueKey(),
              overrides: [
                notificationListProvider.overrideWith(
                  (ref) => Stream.value([]),
                ),
              ],
              child: MaterialApp(
                theme: WebTheme.light(),
                localizationsDelegates: _l10nDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: Scaffold(
                  body: Align(
                    alignment: Alignment.bottomRight,
                    child: Builder(
                      builder: (context) => TextButton(
                        key: key,
                        focusNode: trigger,
                        onPressed: () => showNotificationDropdown(
                          buttonContext: context,
                          onOpenItem: (_, _) =>
                              fail('No notification should be opened'),
                          onViewAll: () => viewAllCalls++,
                        ),
                        child: const Text('Notifications'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          trigger.requestFocus();
          await tester.pump();
          await tester.tap(find.byKey(key));
          await tester.pumpAndSettle();
          expect(find.byType(NotificationDropdownPanel), findsOneWidget);
          final bounds = tester.getRect(find.byType(NotificationDropdownPanel));
          expect(bounds.left, greaterThanOrEqualTo(8));
          expect(bounds.top, greaterThanOrEqualTo(8));
          expect(bounds.right, lessThanOrEqualTo(size.width - 8));
          expect(bounds.bottom, lessThanOrEqualTo(size.height - 8));
          expect(tester.takeException(), isNull);
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
          expect(find.byType(NotificationDropdownPanel), findsNothing);
          expect(trigger.hasFocus, isTrue);
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pumpAndSettle();
          expect(find.byType(NotificationDropdownPanel), findsOneWidget);
          await tester.tap(find.text('View all'));
          await tester.pumpAndSettle();
          expect(find.byType(NotificationDropdownPanel), findsNothing);
          expect(viewAllCalls, 1);
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
          trigger.dispose();
          await tester.binding.setSurfaceSize(null);
        }
      },
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('notification bell renders without badge when unread is zero', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          unreadNotificationCountProvider.overrideWith((ref) async => 0),
          notificationListProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: MaterialApp(
          theme: WebTheme.light(),
          localizationsDelegates: _l10nDelegates,
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
          unreadNotificationCountProvider.overrideWith((ref) async => 0),
          notificationListProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: MaterialApp(
          theme: WebTheme.light(),
          localizationsDelegates: _l10nDelegates,
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

  testWidgets('mark all read closes dropdown and clears badge', (tester) async {
    final repo = _FakeNotificationsRepository([_unreadItem()]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [notificationsRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: WebTheme.light(),
          localizationsDelegates: _l10nDelegates,
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

    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Mark all read'), findsOneWidget);

    await tester.tap(find.text('Mark all read'));
    await tester.pumpAndSettle();

    expect(find.text('Mark all read'), findsNothing);
    expect(find.text('1'), findsNothing);
    expect(await repo.unreadCount(), 0);
  });
}
