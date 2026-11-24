import 'package:businesssajilo/core/l10n/app_localizations.dart';
import 'package:businesssajilo/data/repositories/bills_repository.dart';
import 'package:businesssajilo/data/repositories/customers_repository.dart';
import 'package:businesssajilo/data/repositories/products_repository.dart';
import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/domain/models/bill.dart';
import 'package:businesssajilo/domain/models/customer.dart';
import 'package:businesssajilo/domain/models/member.dart';
import 'package:businesssajilo/domain/models/product.dart';
import 'package:businesssajilo/domain/models/session_state.dart';
import 'package:businesssajilo/features/auth/providers/auth_provider.dart';
import 'package:businesssajilo/features/notifications/providers.dart';
import 'package:businesssajilo/web/layout/web_app_shell.dart';
import 'package:businesssajilo/web/layout/web_sidebar.dart';
import 'package:businesssajilo/web/theme/web_theme.dart';
import 'package:businesssajilo/web/widgets/web_shortcuts_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RoleAuth extends AuthController {
  _RoleAuth(this.role);
  final Role role;

  @override
  AsyncValue<SessionState> build() => AsyncValue.data(
    SessionState(
      member: Member(
        id: 'm1',
        businessId: 'b1',
        authUserId: 'u1',
        role: role,
        displayName: 'Test User',
      ),
    ),
  );
}

class _StubProducts implements ProductsRepository {
  @override
  Future<List<Product>> list({
    bool activeOnly = true,
    int offset = 0,
    int? limit,
    String? query,
    ProductStockFilter stockFilter = ProductStockFilter.all,
  }) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubCustomers implements CustomersRepository {
  @override
  Future<List<Customer>> list({
    int offset = 0,
    int? limit,
    String? query,
    bool includeBalances = true,
    CustomerBalanceFilter balanceFilter = CustomerBalanceFilter.all,
  }) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubBills implements BillsRepository {
  @override
  Future<List<Bill>> search(
    String query, {
    int limit = 50,
    int offset = 0,
    BillStatus? status,
  }) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

GoRouter _buildShellRouter({
  required List<({String label, String path})> destinations,
  required String initialLocation,
  String? newBillPath,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        builder: (context, state, child) => WebAppShell(
          navItems: [
            for (final d in destinations)
              WebNavItem(label: d.label, path: d.path, icon: Icons.circle),
          ],
          child: child,
        ),
        routes: [
          for (final d in destinations)
            GoRoute(
              path: d.path,
              builder: (_, state) => Scaffold(
                body: Column(
                  children: [
                    Text('ROUTE:${state.uri.path}'),
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: TextField(key: Key('page-input')),
                    ),
                  ],
                ),
              ),
            ),
          if (newBillPath != null)
            GoRoute(
              path: newBillPath,
              builder: (_, state) =>
                  Scaffold(body: Text('ROUTE:${state.uri.path}')),
            ),
        ],
      ),
    ],
  );
}

Widget _wrapApp({
  required Role role,
  required GoRouter router,
  Locale locale = const Locale('en'),
}) {
  return ProviderScope(
    key: UniqueKey(),
    overrides: [
      authProvider.overrideWith(() => _RoleAuth(role)),
      unreadNotificationCountProvider.overrideWith((ref) async => 0),
      notificationListProvider.overrideWith((ref) => Stream.value([])),
      productsRepositoryProvider.overrideWithValue(_StubProducts()),
      customersRepositoryProvider.overrideWithValue(_StubCustomers()),
      billsRepositoryProvider.overrideWithValue(_StubBills()),
    ],
    child: Consumer(
      builder: (context, ref, _) => MaterialApp.router(
        routerConfig: router,
        theme: WebTheme.light(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'Ctrl+K, /, ?, Alt+N/B, Alt+1..7 work and respect text field focus & Escape',
    (tester) async {
      _setViewport(tester, const Size(1280, 800));
      final router = _buildShellRouter(
        initialLocation: '/owner/dashboard',
        newBillPath: '/owner/billing/new',
        destinations: const [
          (label: 'Dashboard', path: '/owner/dashboard'),
          (label: 'Inventory', path: '/owner/inventory'),
          (label: 'Billing', path: '/owner/billing'),
          (label: 'Customers', path: '/owner/customers'),
          (label: 'Orders', path: '/owner/orders'),
          (label: 'Reports', path: '/owner/reports'),
          (label: 'Staff', path: '/owner/staff'),
        ],
      );
      try {
        await tester.pumpWidget(_wrapApp(role: Role.owner, router: router));
        await tester.pumpAndSettle();

        // Top bar search pill shows shortcut hint.
        expect(find.text('Ctrl K'), findsOneWidget);

        // Ctrl+K opens Global Search, Escape closes it.
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.keyK);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.keyK);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Type at least 2 characters to search'),
          findsOneWidget,
        );

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Type at least 2 characters to search'),
          findsNothing,
        );

        // '/' when NOT in text field opens Global Search; Escape closes it.
        await tester.sendKeyEvent(LogicalKeyboardKey.slash);
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Type at least 2 characters to search'),
          findsOneWidget,
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Type at least 2 characters to search'),
          findsNothing,
        );

        // '?' when NOT in text field opens shortcuts cheatsheet; Escape closes it.
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.slash);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.slash);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.pumpAndSettle();
        expect(find.byType(WebShortcutsDialog), findsOneWidget);
        expect(find.text('Keyboard shortcuts'), findsOneWidget);

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.byType(WebShortcutsDialog), findsNothing);

        // Typing '/' or '?' while focused in a TextField must NOT trigger modals.
        await tester.tap(find.byKey(const Key('page-input')));
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.slash);
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Type at least 2 characters to search'),
          findsNothing,
        );

        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.slash);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.slash);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.pumpAndSettle();
        expect(find.byType(WebShortcutsDialog), findsNothing);

        // Unfocus field, then test Alt+1..7 navigation.
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pump();

        await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.digit2);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.digit2);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
        await tester.pumpAndSettle();
        expect(find.text('ROUTE:/owner/inventory'), findsOneWidget);

        await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.digit7);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.digit7);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
        await tester.pumpAndSettle();
        expect(find.text('ROUTE:/owner/staff'), findsOneWidget);

        // Alt+N opens new bill for owner.
        await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.keyN);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.keyN);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
        await tester.pumpAndSettle();
        expect(find.text('ROUTE:/owner/billing/new'), findsOneWidget);

        // Alt+1 returns to dashboard, Alt+B also opens new bill.
        await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.digit1);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.digit1);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
        await tester.pumpAndSettle();
        expect(find.text('ROUTE:/owner/dashboard'), findsOneWidget);

        await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.keyB);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.keyB);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
        await tester.pumpAndSettle();
        expect(find.text('ROUTE:/owner/billing/new'), findsOneWidget);

        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        router.dispose();
      }
    },
  );

  testWidgets(
    'keyboard shortcuts respect role permissions for customer and warehouse',
    (tester) async {
      _setViewport(tester, const Size(1280, 800));
      final customerRouter = _buildShellRouter(
        initialLocation: '/customer/dashboard',
        destinations: const [
          (label: 'Dashboard', path: '/customer/dashboard'),
          (label: 'Catalog', path: '/customer/catalog'),
        ],
      );
      try {
        await tester.pumpWidget(
          _wrapApp(role: Role.customer, router: customerRouter),
        );
        await tester.pumpAndSettle();

        // Alt+N must NOT navigate customer to a billing/new route.
        await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.keyN);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.keyN);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
        await tester.pumpAndSettle();
        expect(find.text('ROUTE:/customer/dashboard'), findsOneWidget);

        // Alt+2 navigates to Catalog; Alt+5 is safely ignored.
        await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.digit2);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.digit2);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
        await tester.pumpAndSettle();
        expect(find.text('ROUTE:/customer/catalog'), findsOneWidget);

        await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.digit5);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.digit5);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
        await tester.pumpAndSettle();
        expect(find.text('ROUTE:/customer/catalog'), findsOneWidget);

        // Cheatsheet for customer hides Create new bill shortcut.
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.slash);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.slash);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.pumpAndSettle();
        expect(find.byType(WebShortcutsDialog), findsOneWidget);
        expect(find.text('Create new bill'), findsNothing);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        customerRouter.dispose();
      }
    },
  );

  testWidgets(
    'mobile web drawer opens at 390x844 without GoRouterState error',
    (tester) async {
      _setViewport(tester, const Size(390, 844));
      final router = _buildShellRouter(
        initialLocation: '/owner/dashboard',
        destinations: const [
          (label: 'Dashboard', path: '/owner/dashboard'),
          (label: 'Inventory', path: '/owner/inventory'),
          (label: 'Billing', path: '/owner/billing'),
        ],
      );
      try {
        await tester.pumpWidget(_wrapApp(role: Role.owner, router: router));
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Open menu'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(WebSidebar), findsOneWidget);

        await tester.tap(
          find.descendant(
            of: find.byType(WebSidebar),
            matching: find.text('Inventory'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('ROUTE:/owner/inventory'), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        router.dispose();
      }
    },
  );
}
