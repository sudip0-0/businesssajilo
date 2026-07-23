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
  // Role-agnostic detail deep links (push notification tap-through).
  if (path.startsWith('/bill/')) return role.canBill;
  if (path.startsWith('/product/')) {
    return role == Role.owner || role == Role.sales || role == Role.warehouse;
  }
  return false;
}
