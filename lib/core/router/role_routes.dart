import '../../domain/enums.dart';

String roleHomePath(Role? role) => switch (role) {
  Role.owner => '/owner',
  Role.sales => '/sales',
  Role.warehouse => '/warehouse',
  Role.customer => '/customer',
  null => '/login',
};

bool pathAllowedForRole(String path, Role role) {
  if (path.startsWith('/owner')) return role == Role.owner;
  if (path.startsWith('/sales')) return role == Role.sales;
  if (path.startsWith('/warehouse')) return role == Role.warehouse;
  if (path.startsWith('/customer')) return role == Role.customer;

  // Shared notification inbox.
  if (path == '/notifications') return true;

  // Role-agnostic detail deep links (push notification tap-through).
  if (path.startsWith('/bill/')) {
    // Customers may open their own bills; RLS enforces ownership.
    // Warehouse never bills.
    return role.canBill || role == Role.customer;
  }
  if (path.startsWith('/product/')) {
    return role == Role.owner || role == Role.sales || role == Role.warehouse;
  }
  if (path.startsWith('/order/')) {
    // Chat and order detail are available to all roles that receive those
    // notification types; warehouse fulfillment uses order screens too.
    return true;
  }
  if (path.startsWith('/quote/')) {
    return role != Role.warehouse;
  }
  return false;
}
