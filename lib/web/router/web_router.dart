import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/mobile_router.dart';
import '../../core/router/router_keys.dart';
import '../../features/auth/change_password_screen.dart';
import '../../domain/models/session_state.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/billing/bill_form_leave_confirm.dart';
import '../../features/billing/providers.dart';
import '../auth/web_login_page.dart';
import '../auth/web_register_page.dart';
import '../features/billing/web_customer_bill_detail_page.dart';
import '../features/customers/web_customer_form_page.dart';
import '../features/customers/web_customer_ledger_page.dart';
import '../features/customers/web_customer_list_page.dart';
import '../features/dashboard/web_customer_dashboard_page.dart';
import '../features/dashboard/web_owner_dashboard_page.dart';
import '../features/dashboard/web_sales_dashboard_page.dart';
import '../features/dashboard/web_warehouse_dashboard_page.dart';
import '../features/notifications/web_notifications_page.dart';
import '../features/settings/web_settings_page.dart';
import '../features/staff/web_staff_list_page.dart';
import '../shell/customer_web_shell.dart';
import '../shell/owner_web_shell.dart';
import '../shell/sales_web_shell.dart';
import '../shell/warehouse_web_shell.dart';
import 'deferred_page.dart';
import 'web_role_routes.dart';

// Heavy feature modules — loaded on first navigation to shrink initial JS.
import '../features/billing/web_bill_form_page.dart' deferred as bill_form;
import '../features/billing/web_bill_list_page.dart' deferred as bill_list;
import '../features/billing/web_credit_note_form_page.dart'
    deferred as credit_note;
import '../features/inventory/web_product_form_page.dart'
    deferred as product_form;
import '../features/inventory/web_product_list_page.dart'
    deferred as product_list;
import '../features/orders/web_catalog_page.dart' deferred as catalog;
import '../features/orders/web_order_detail_page.dart' deferred as order_detail;
import '../features/orders/web_order_list_page.dart' deferred as order_list;
import '../features/reports/web_dues_aging_page.dart' deferred as dues_aging;
import '../features/reports/web_reports_hub_page.dart' deferred as reports_hub;
import '../features/reports/web_sales_report_page.dart' deferred as sales_report;
import '../features/reports/web_stock_report_page.dart' deferred as stock_report;

final webRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authProvider, (_, _) => refresh.value++);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    refreshListenable: refresh,
    initialLocation: '/',
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      // Prefer full URI path so bare role roots like `/owner` redirect even
      // when no GoRoute matches (matchedLocation can be empty then).
      final rawPath = state.uri.path.isNotEmpty
          ? state.uri.path
          : state.matchedLocation;
      final path = rawPath.length > 1 && rawPath.endsWith('/')
          ? rawPath.substring(0, rawPath.length - 1)
          : rawPath;
      final isAuthRoute = path == '/login' || path == '/register';

      if (auth.isLoading) return null;

      final session = auth.value ?? SessionState.empty;
      final loggedIn = session.isAuthenticated;

      if (!loggedIn) {
        return isAuthRoute ? null : '/login';
      }

      final role = session.member!.role;
      final home = webRoleHomePath(role);

      // Owner reset this member's password: block the app until changed.
      if (session.mustChangePassword) {
        return path == '/change-password' ? null : '/change-password';
      }
      if (path == '/change-password') return home;

      if (isAuthRoute || path == '/') return home;
      if (!webPathAllowedForRole(path, role)) return home;

      final roleRootHome = webRoleRootRedirect(path);
      if (roleRootHome != null) return roleRootHome;

      // Warehouse cannot access billing routes.
      if (path.contains('/billing') && !webBillingPathAllowed(role)) {
        return home;
      }

      return null;
    },
    errorBuilder: (context, state) => const RouterNotFoundScreen(),
    routes: [
      GoRoute(path: '/', builder: (_, _) => const RouterSplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const WebLoginPage()),
      GoRoute(path: '/register', builder: (_, _) => const WebRegisterPage()),
      GoRoute(
        path: '/change-password',
        builder: (_, _) => const ForcedChangePasswordScreen(),
      ),
      GoRoute(
        path: '/notifications',
        redirect: (context, state) {
          final session = ref.read(authProvider).value;
          final role = session?.member?.role;
          if (role == null) return '/login';
          return '${webRoleBasePath(role)}/notifications';
        },
      ),
      // Bare role roots → home (also handled in [redirect] for safety).
      GoRoute(
        path: '/owner',
        redirect: (_, _) => '/owner/dashboard',
      ),
      GoRoute(
        path: '/sales',
        redirect: (_, _) => '/sales/dashboard',
      ),
      GoRoute(
        path: '/warehouse',
        redirect: (_, _) => '/warehouse/stock',
      ),
      GoRoute(
        path: '/customer',
        redirect: (_, _) => '/customer/dashboard',
      ),
      _ownerRoutes(),
      _salesRoutes(),
      _warehouseRoutes(),
      _customerRoutes(),
    ],
  );
});

/// Blocks leaving `/billing/new` when the draft has unsaved content.
Future<bool> _onExitBillForm(BuildContext context, GoRouterState state) async {
  final container = ProviderScope.containerOf(context);
  if (!container.read(billFormDirtyProvider)) return true;
  final leave = await confirmLeaveUnsavedBill(context);
  if (leave) {
    container.read(billFormDirtyProvider.notifier).clear();
  }
  return leave;
}

ShellRoute _ownerRoutes() {
  return ShellRoute(
    builder: (context, state, child) => OwnerWebShell(child: child),
    routes: [
      GoRoute(
        path: '/owner/dashboard',
        builder: (_, _) => const WebOwnerDashboardPage(),
      ),
      GoRoute(
        path: '/owner/inventory',
        builder: (_, state) => DeferredPage(
          load: product_list.loadLibrary,
          builder: () => product_list.WebProductListPage(
            selectedProductId: state.uri.queryParameters['id'],
            canEdit: true,
            canManageStock: true,
          ),
        ),
        routes: [
          GoRoute(
            path: 'new',
            builder: (_, _) => DeferredPage(
              load: product_form.loadLibrary,
              builder: () => product_form.WebProductFormPage(
                inventoryListPath: '/owner/inventory',
              ),
            ),
          ),
          GoRoute(
            path: ':productId',
            builder: (_, state) => DeferredPage(
              load: product_list.loadLibrary,
              builder: () => product_list.WebProductListPage(
                selectedProductId: state.pathParameters['productId'],
                canEdit: true,
                canManageStock: true,
              ),
            ),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (_, state) => DeferredPage(
                  load: product_form.loadLibrary,
                  builder: () => product_form.WebProductFormPage(
                    productId: state.pathParameters['productId'],
                    inventoryListPath: '/owner/inventory',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/owner/customers',
        builder: (_, state) => WebCustomerListPage(
          selectedCustomerId: state.uri.queryParameters['id'],
          canEdit: true,
          canRecordPayments: true,
        ),
        routes: [
          GoRoute(path: 'new', builder: (_, _) => const WebCustomerFormPage()),
          GoRoute(
            path: ':customerId',
            builder: (_, state) => WebCustomerListPage(
              selectedCustomerId: state.pathParameters['customerId'],
              canEdit: true,
              canRecordPayments: true,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/owner/billing',
        builder: (_, state) => DeferredPage(
          load: bill_list.loadLibrary,
          builder: () => bill_list.WebBillListPage(
            selectedBillId: state.uri.queryParameters['id'],
          ),
        ),
        routes: [
          GoRoute(
            path: 'new',
            onExit: _onExitBillForm,
            builder: (_, state) => DeferredPage(
              load: bill_form.loadLibrary,
              builder: () => bill_form.WebBillFormPage(
                orderId: state.uri.queryParameters['orderId'],
              ),
            ),
          ),
          GoRoute(
            path: ':billId',
            builder: (_, state) => DeferredPage(
              load: bill_list.loadLibrary,
              builder: () => bill_list.WebBillListPage(
                selectedBillId: state.pathParameters['billId'],
              ),
            ),
            routes: [
              GoRoute(
                path: 'return',
                builder: (_, state) => DeferredPage(
                  load: credit_note.loadLibrary,
                  builder: () => credit_note.WebCreditNoteFormPage(
                    billId: state.pathParameters['billId']!,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/owner/orders',
        builder: (_, state) => DeferredPage(
          load: order_list.loadLibrary,
          builder: () => order_list.WebOrderListPage(
            selectedOrderId: state.uri.queryParameters['id'],
          ),
        ),
        routes: [
          GoRoute(
            path: ':orderId',
            builder: (_, state) {
              return DeferredPage(
                load: order_detail.loadLibrary,
                builder: () => order_detail.WebOrderDetailPage(
                  orderId: state.pathParameters['orderId']!,
                  ordersListPath: '/owner/orders',
                ),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/owner/staff',
        builder: (_, _) => const WebStaffListPage(),
      ),
      // Sibling routes (not nested) so each report page replaces the hub
      // instead of stacking on top of it — nested stacks caused blank bodies.
      GoRoute(
        path: '/owner/reports',
        builder: (_, _) => DeferredPage(
          load: reports_hub.loadLibrary,
          builder: () => reports_hub.WebReportsHubPage(),
        ),
      ),
      GoRoute(
        path: '/owner/reports/sales',
        builder: (_, state) => DeferredPage(
          load: sales_report.loadLibrary,
          builder: () => sales_report.WebSalesReportPage(
            initialPeriod: state.uri.queryParameters['period'],
          ),
        ),
      ),
      GoRoute(
        path: '/owner/reports/dues',
        builder: (_, state) => DeferredPage(
          load: dues_aging.loadLibrary,
          builder: () => dues_aging.WebDuesAgingPage(
            initialBucket: state.uri.queryParameters['bucket'],
          ),
        ),
      ),
      GoRoute(
        path: '/owner/reports/stock',
        builder: (_, state) => DeferredPage(
          load: stock_report.loadLibrary,
          builder: () => stock_report.WebStockReportPage(
            initialStatus: state.uri.queryParameters['status'],
          ),
        ),
      ),
      GoRoute(
        path: '/owner/settings',
        builder: (_, _) => const WebSettingsPage(),
      ),
      GoRoute(
        path: '/owner/notifications',
        builder: (_, _) => const WebNotificationsPage(),
      ),
    ],
  );
}

ShellRoute _salesRoutes() {
  return ShellRoute(
    builder: (context, state, child) => SalesWebShell(child: child),
    routes: [
      GoRoute(
        path: '/sales/dashboard',
        builder: (_, _) => const WebSalesDashboardPage(),
      ),
      GoRoute(
        path: '/sales/stock',
        builder: (_, state) => DeferredPage(
          load: product_list.loadLibrary,
          builder: () => product_list.WebProductListPage(
            selectedProductId: state.uri.queryParameters['id'],
            canEdit: true,
          ),
        ),
        routes: [
          GoRoute(
            path: 'new',
            builder: (_, _) => DeferredPage(
              load: product_form.loadLibrary,
              builder: () => product_form.WebProductFormPage(
                inventoryListPath: '/sales/stock',
              ),
            ),
          ),
          GoRoute(
            path: ':productId',
            builder: (_, state) => DeferredPage(
              load: product_list.loadLibrary,
              builder: () => product_list.WebProductListPage(
                selectedProductId: state.pathParameters['productId'],
                canEdit: true,
              ),
            ),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (_, state) => DeferredPage(
                  load: product_form.loadLibrary,
                  builder: () => product_form.WebProductFormPage(
                    productId: state.pathParameters['productId'],
                    inventoryListPath: '/sales/stock',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/sales/orders',
        builder: (_, state) => DeferredPage(
          load: order_list.loadLibrary,
          builder: () => order_list.WebOrderListPage(
            selectedOrderId: state.uri.queryParameters['id'],
          ),
        ),
        routes: [
          GoRoute(
            path: ':orderId',
            builder: (_, state) {
              return DeferredPage(
                load: order_detail.loadLibrary,
                builder: () => order_detail.WebOrderDetailPage(
                  orderId: state.pathParameters['orderId']!,
                  ordersListPath: '/sales/orders',
                ),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/sales/customers',
        builder: (_, state) => WebCustomerListPage(
          selectedCustomerId: state.uri.queryParameters['id'],
          canRecordPayments: true,
        ),
        routes: [
          GoRoute(
            path: ':customerId',
            builder: (_, state) => WebCustomerListPage(
              selectedCustomerId: state.pathParameters['customerId'],
              canRecordPayments: true,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/sales/billing',
        builder: (_, state) => DeferredPage(
          load: bill_list.loadLibrary,
          builder: () => bill_list.WebBillListPage(
            selectedBillId: state.uri.queryParameters['id'],
          ),
        ),
        routes: [
          GoRoute(
            path: 'new',
            onExit: _onExitBillForm,
            builder: (_, state) => DeferredPage(
              load: bill_form.loadLibrary,
              builder: () => bill_form.WebBillFormPage(
                orderId: state.uri.queryParameters['orderId'],
              ),
            ),
          ),
          GoRoute(
            path: ':billId',
            builder: (_, state) => DeferredPage(
              load: bill_list.loadLibrary,
              builder: () => bill_list.WebBillListPage(
                selectedBillId: state.pathParameters['billId'],
              ),
            ),
            routes: [
              GoRoute(
                path: 'return',
                builder: (_, state) => DeferredPage(
                  load: credit_note.loadLibrary,
                  builder: () => credit_note.WebCreditNoteFormPage(
                    billId: state.pathParameters['billId']!,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/sales/notifications',
        builder: (_, _) => const WebNotificationsPage(),
      ),
    ],
  );
}

ShellRoute _warehouseRoutes() {
  return ShellRoute(
    builder: (context, state, child) => WarehouseWebShell(child: child),
    routes: [
      GoRoute(
        path: '/warehouse/stock',
        builder: (_, state) => DeferredPage(
          load: product_list.loadLibrary,
          builder: () => product_list.WebProductListPage(
            selectedProductId: state.uri.queryParameters['id'],
            canManageStock: true,
          ),
        ),
        routes: [
          GoRoute(
            path: ':productId',
            builder: (_, state) => DeferredPage(
              load: product_list.loadLibrary,
              builder: () => product_list.WebProductListPage(
                selectedProductId: state.pathParameters['productId'],
                canManageStock: true,
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/warehouse/billing',
        builder: (_, state) => DeferredPage(
          load: bill_list.loadLibrary,
          builder: () => bill_list.WebBillListPage(
            selectedBillId: state.uri.queryParameters['id'],
          ),
        ),
        routes: [
          GoRoute(
            path: 'new',
            onExit: _onExitBillForm,
            builder: (_, state) => DeferredPage(
              load: bill_form.loadLibrary,
              builder: () => bill_form.WebBillFormPage(
                orderId: state.uri.queryParameters['orderId'],
              ),
            ),
          ),
          GoRoute(
            path: ':billId',
            builder: (_, state) => DeferredPage(
              load: bill_list.loadLibrary,
              builder: () => bill_list.WebBillListPage(
                selectedBillId: state.pathParameters['billId'],
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/warehouse/dashboard',
        builder: (_, _) => const WebWarehouseDashboardPage(),
        redirect: (_, _) => '/warehouse/stock',
      ),
      GoRoute(
        path: '/warehouse/notifications',
        builder: (_, _) => const WebNotificationsPage(),
      ),
    ],
  );
}

ShellRoute _customerRoutes() {
  return ShellRoute(
    builder: (context, state, child) => CustomerWebShell(child: child),
    routes: [
      GoRoute(
        path: '/customer/dashboard',
        builder: (_, _) => const WebCustomerDashboardPage(),
      ),
      GoRoute(
        path: '/customer/catalog',
        builder: (_, _) => DeferredPage(
          load: catalog.loadLibrary,
          builder: () => catalog.WebCatalogPage(),
        ),
      ),
      GoRoute(
        path: '/customer/orders',
        builder: (_, state) => DeferredPage(
          load: order_list.loadLibrary,
          builder: () => order_list.WebOrderListPage(
            selectedOrderId: state.uri.queryParameters['id'],
            ownOnly: true,
          ),
        ),
        routes: [
          GoRoute(
            path: ':orderId',
            builder: (_, state) => DeferredPage(
              load: order_list.loadLibrary,
              builder: () => order_list.WebOrderListPage(
                selectedOrderId: state.pathParameters['orderId'],
                ownOnly: true,
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/customer/dues',
        builder: (_, _) => const WebCustomerLedgerPage(),
      ),
      GoRoute(
        path: '/customer/billing/:billId',
        builder: (_, state) => WebCustomerBillDetailPage(
          billId: state.pathParameters['billId']!,
        ),
      ),
      GoRoute(
        path: '/customer/notifications',
        builder: (_, _) => const WebNotificationsPage(),
      ),
    ],
  );
}
