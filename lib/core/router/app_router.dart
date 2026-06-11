import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/login_screen.dart';
import '../../domain/models/session_state.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/register_screen.dart';
import '../../features/shell/customer_shell.dart';
import '../../features/shell/owner_shell.dart';
import '../../features/shell/sales_shell.dart';
import '../../features/shell/warehouse_shell.dart';
import 'role_routes.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authProvider, (_, _) => refresh.value++);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
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

      if (isAuthRoute || path == '/') return home;
      if (!pathAllowedForRole(path, role)) return home;
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(path: '/owner', builder: (_, _) => const OwnerShell()),
      GoRoute(path: '/sales', builder: (_, _) => const SalesShell()),
      GoRoute(path: '/warehouse', builder: (_, _) => const WarehouseShell()),
      GoRoute(path: '/customer', builder: (_, _) => const CustomerShell()),
    ],
  );
});
