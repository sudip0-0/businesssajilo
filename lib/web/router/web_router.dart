import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/mobile_router.dart';
import '../../core/router/router_keys.dart';
import '../../domain/models/session_state.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/onboarding/owner_onboarding_overlay.dart';
import '../auth/web_login_page.dart';
import '../auth/web_register_page.dart';
import '../features/billing/web_bill_form_page.dart';
import '../features/billing/web_bill_list_page.dart';
import '../features/customers/web_customer_form_page.dart';
import '../features/customers/web_customer_ledger_page.dart';
import '../features/customers/web_customer_list_page.dart';
import '../features/dashboard/web_customer_dashboard_page.dart';
import '../features/dashboard/web_owner_dashboard_page.dart';
import '../features/dashboard/web_sales_dashboard_page.dart';
import '../features/dashboard/web_warehouse_dashboard_page.dart';
import '../features/inventory/web_product_detail_page.dart';
import '../features/inventory/web_product_form_page.dart';
import '../features/inventory/web_product_list_page.dart';
import '../features/notifications/web_notifications_page.dart';
import '../features/orders/web_catalog_page.dart';
import '../features/orders/web_fulfillment_page.dart';
import '../features/orders/web_order_detail_page.dart';
import '../features/orders/web_order_list_page.dart';
import '../features/reports/web_dues_aging_page.dart';
import '../features/reports/web_reports_hub_page.dart';
import '../features/reports/web_sales_summary_page.dart';
import '../features/reports/web_stock_valuation_page.dart';
import '../features/settings/web_settings_page.dart';
import '../features/staff/web_staff_list_page.dart';
import '../shell/customer_web_shell.dart';
import '../shell/owner_web_shell.dart';
import '../shell/sales_web_shell.dart';
import '../shell/warehouse_web_shell.dart';
import 'web_role_routes.dart';

final webRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authProvider, (_, _) => refresh.value++);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    refreshListenable: refresh,
    initialLocation: '/',
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final path = state.matchedLocation;
      final isAuthRoute = path == '/login' || path == '/register';

      if (auth.isLoading) return null;

      final session = auth.value ?? SessionState.empty;
      final loggedIn = session.isAuthenticated;

      if (!loggedIn) {
        return isAuthRoute ? null : '/login';
      }

      final role = session.member!.role;
      final home = webRoleHomePath(role);

      if (isAuthRoute || path == '/') return home;
      if (!webPathAllowedForRole(path, role)) return home;

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
        path: '/notifications',
        builder: (_, _) => const WebNotificationsPage(),
      ),
      _ownerRoutes(),
      _salesRoutes(),
      _warehouseRoutes(),
      _customerRoutes(),
    ],
  );
});

ShellRoute _ownerRoutes() {
  return ShellRoute(
    builder: (context, state, child) => OwnerOnboardingOverlay(
      child: OwnerWebShell(child: child),
    ),
    routes: [
      GoRoute(
        path: '/owner/dashboard',
        builder: (_, _) => const WebOwnerDashboardPage(),
      ),
      GoRoute(
        path: '/owner/inventory',
        builder: (_, _) => const WebProductListPage(
          canEdit: true,
          canManageStock: true,
        ),
        routes: [
          GoRoute(
            path: 'new',
            builder: (_, _) => const WebProductFormPage(
              inventoryListPath: '/owner/inventory',
            ),
          ),
          GoRoute(
            path: ':productId',
            builder: (_, state) => WebProductDetailPage(
              productId: state.pathParameters['productId']!,
              inventoryListPath: '/owner/inventory',
            ),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (_, state) => WebProductFormPage(
                  productId: state.pathParameters['productId'],
                  inventoryListPath: '/owner/inventory',
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
          GoRoute(
            path: 'new',
            builder: (_, _) => const WebCustomerFormPage(),
          ),
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
        builder: (_, state) => WebBillListPage(
          selectedBillId: state.uri.queryParameters['id'],
        ),
        routes: [
          GoRoute(
            path: 'new',
            builder: (_, _) => const WebBillFormPage(),
          ),
          GoRoute(
            path: ':billId',
            builder: (_, state) => WebBillListPage(
              selectedBillId: state.pathParameters['billId'],
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/owner/orders',
        builder: (_, state) => WebOrderListPage(
          selectedOrderId: state.uri.queryParameters['id'],
        ),
        routes: [
          GoRoute(
            path: ':orderId',
            builder: (_, state) {
              final tab = int.tryParse(
                    state.uri.queryParameters['tab'] ?? '0',
                  ) ??
                  0;
              return WebOrderDetailPage(
                orderId: state.pathParameters['orderId']!,
                initialTab: tab,
                ordersListPath: '/owner/orders',
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/owner/staff',
        builder: (_, _) => const WebStaffListPage(),
      ),
      GoRoute(
        path: '/owner/reports',
        builder: (_, _) => const WebReportsHubPage(),
        routes: [
          GoRoute(
            path: 'sales',
            builder: (_, _) => const WebSalesSummaryPage(),
          ),
          GoRoute(
            path: 'dues',
            builder: (_, _) => const WebDuesAgingPage(),
          ),
          GoRoute(
            path: 'stock',
            builder: (_, _) => const WebStockValuationPage(),
          ),
        ],
      ),
      GoRoute(
        path: '/owner/settings',
        builder: (_, _) => const WebSettingsPage(),
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
        builder: (_, _) => const WebProductListPage(),
        routes: [
          GoRoute(
            path: ':productId',
            builder: (_, state) => WebProductDetailPage(
              productId: state.pathParameters['productId']!,
              inventoryListPath: '/sales/stock',
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/sales/orders',
        builder: (_, state) => WebOrderListPage(
          selectedOrderId: state.uri.queryParameters['id'],
        ),
        routes: [
          GoRoute(
            path: ':orderId',
            builder: (_, state) {
              final tab = int.tryParse(
                    state.uri.queryParameters['tab'] ?? '0',
                  ) ??
                  0;
              return WebOrderDetailPage(
                orderId: state.pathParameters['orderId']!,
                initialTab: tab,
                ordersListPath: '/sales/orders',
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
        builder: (_, state) => WebBillListPage(
          selectedBillId: state.uri.queryParameters['id'],
        ),
        routes: [
          GoRoute(
            path: 'new',
            builder: (_, _) => const WebBillFormPage(),
          ),
          GoRoute(
            path: ':billId',
            builder: (_, state) => WebBillListPage(
              selectedBillId: state.pathParameters['billId'],
            ),
          ),
        ],
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
        builder: (_, _) => const WebProductListPage(
          canManageStock: true,
        ),
        routes: [
          GoRoute(
            path: ':productId',
            builder: (_, state) => WebProductDetailPage(
              productId: state.pathParameters['productId']!,
              inventoryListPath: '/warehouse/stock',
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/warehouse/fulfillment',
        builder: (_, state) => WebFulfillmentPage(
          selectedOrderId: state.uri.queryParameters['id'],
        ),
        routes: [
          GoRoute(
            path: ':orderId',
            builder: (_, state) => WebFulfillmentPage(
              selectedOrderId: state.pathParameters['orderId'],
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/warehouse/dashboard',
        builder: (_, _) => const WebWarehouseDashboardPage(),
        redirect: (_, _) => '/warehouse/stock',
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
        builder: (_, _) => const WebCatalogPage(),
      ),
      GoRoute(
        path: '/customer/orders',
        builder: (_, state) => WebOrderListPage(
          selectedOrderId: state.uri.queryParameters['id'],
          ownOnly: true,
        ),
        routes: [
          GoRoute(
            path: ':orderId',
            builder: (_, state) => WebOrderListPage(
              selectedOrderId: state.pathParameters['orderId'],
              ownOnly: true,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/customer/dues',
        builder: (_, _) => const WebCustomerLedgerPage(),
      ),
    ],
  );
}
