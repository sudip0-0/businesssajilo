import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../../features/auth/change_password_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../domain/enums.dart';
import '../../domain/models/session_state.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/register_screen.dart';
import '../../features/billing/bill_detail_screen.dart';
import '../../features/chat/order_chat_screen.dart';
import '../../features/inventory/product_detail_screen.dart';
import '../../features/notifications/notification_list_screen.dart';
import '../../features/orders/order_detail_screen.dart';
import '../../features/quotes/quote_detail_screen.dart';
import '../../features/shell/customer_shell.dart';
import '../../features/shell/owner_shell.dart';
import '../../features/shell/sales_shell.dart';
import '../../features/shell/warehouse_shell.dart';
import 'role_routes.dart';
import 'router_keys.dart';

final mobileRouterProvider = Provider<GoRouter>((ref) {
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
      final home = roleHomePath(role);

      // Owner reset this member's password: block the app until changed.
      if (session.mustChangePassword) {
        return path == '/change-password' ? null : '/change-password';
      }
      if (path == '/change-password') return home;

      if (isAuthRoute || path == '/') return home;
      if (!pathAllowedForRole(path, role)) return home;
      return null;
    },
    errorBuilder: (context, state) => const RouterNotFoundScreen(),
    routes: [
      GoRoute(path: '/', builder: (_, _) => const RouterSplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(
        path: '/change-password',
        builder: (_, _) => const ForcedChangePasswordScreen(),
      ),
      GoRoute(path: '/owner', builder: (_, _) => const OwnerShell()),
      GoRoute(path: '/sales', builder: (_, _) => const SalesShell()),
      GoRoute(path: '/warehouse', builder: (_, _) => const WarehouseShell()),
      GoRoute(path: '/customer', builder: (_, _) => const CustomerShell()),
      GoRoute(
        path: '/bill/:billId',
        builder: (context, state) =>
            BillDetailScreen(billId: state.pathParameters['billId']!),
      ),
      GoRoute(
        path: '/product/:productId',
        builder: (context, state) {
          final role = ref.read(authProvider).value?.member?.role;
          return ProductDetailScreen(
            productId: state.pathParameters['productId']!,
            canManageStock: role?.canManageStock ?? false,
            canEditProduct: role?.canManageProducts ?? false,
          );
        },
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, _) => const NotificationListScreen(),
      ),
      GoRoute(
        path: '/order/:orderId',
        builder: (context, state) =>
            OrderDetailScreen(orderId: state.pathParameters['orderId']!),
        routes: [
          GoRoute(
            path: 'chat',
            builder: (context, state) =>
                OrderChatScreen(orderId: state.pathParameters['orderId']!),
          ),
        ],
      ),
      GoRoute(
        path: '/quote/:quoteId',
        builder: (context, state) =>
            QuoteDetailScreen(quoteId: state.pathParameters['quoteId']!),
      ),
    ],
  );
});

/// Brand-colored splash shown while session restore decides the home route.
class RouterSplashScreen extends StatelessWidget {
  const RouterSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: BsColors.primary,
      body: Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}

class RouterNotFoundScreen extends StatelessWidget {
  const RouterNotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 56, color: BsColors.primary),
            const SizedBox(height: 12),
            Text(l10n.pageNotFound),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/'),
              child: Text(l10n.goHome),
            ),
          ],
        ),
      ),
    );
  }
}
