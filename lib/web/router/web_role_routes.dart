import '../../domain/enums.dart';

/// Web role home paths use nested routes for bookmarkable URLs.
String webRoleHomePath(Role? role) => switch (role) {
      Role.owner => '/owner/dashboard',
      Role.sales => '/sales/dashboard',
      Role.warehouse => '/warehouse/stock',
      Role.customer => '/customer/dashboard',
      null => '/login',
    };

bool webPathAllowedForRole(String path, Role role) {
  if (path.startsWith('/owner')) return role == Role.owner;
  if (path.startsWith('/sales')) return role == Role.sales;
  if (path.startsWith('/warehouse')) return role == Role.warehouse;
  if (path.startsWith('/customer')) return role == Role.customer;
  if (path == '/login' || path == '/register' || path == '/') return true;
  return false;
}

/// Warehouse must never access billing routes on web.
bool webBillingPathAllowed(Role role) =>
    role == Role.owner || role == Role.sales;
