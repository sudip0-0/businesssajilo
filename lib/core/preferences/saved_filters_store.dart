import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/enums.dart';

/// Tenant, member, and role scope for persisted list filters.
///
/// Every saved filter entry is namespaced by [businessId], [memberId], and
/// [role] so switching accounts, tenants, or roles never leaks filter state.
class FilterScope {
  const FilterScope({
    required this.businessId,
    required this.memberId,
    required this.role,
  });

  final String businessId;
  final String memberId;
  final Role role;

  bool get isValid =>
      businessId.trim().isNotEmpty && memberId.trim().isNotEmpty;

  String get keyPrefix =>
      'bs_saved_filters_v1::${businessId.trim()}::${memberId.trim()}::${role.name}';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FilterScope &&
            other.businessId == businessId &&
            other.memberId == memberId &&
            other.role == role;
  }

  @override
  int get hashCode => Object.hash(businessId, memberId, role);
}

enum InventorySortField { name, quantity, price }

class InventoryListFilterState {
  const InventoryListFilterState({
    this.stockFilter = ProductStockFilter.all,
    this.showInactive = false,
    this.sortField = InventorySortField.name,
    this.sortAscending = true,
  });

  static const defaults = InventoryListFilterState();

  final ProductStockFilter stockFilter;
  final bool showInactive;
  final InventorySortField sortField;
  final bool sortAscending;

  bool get isDefault =>
      stockFilter == ProductStockFilter.all &&
      !showInactive &&
      sortField == InventorySortField.name &&
      sortAscending;

  int get activeCount {
    var count = 0;
    if (stockFilter != ProductStockFilter.all) count++;
    if (showInactive) count++;
    if (sortField != InventorySortField.name || !sortAscending) count++;
    return count;
  }

  InventoryListFilterState sanitizeForRole({required bool canEdit}) {
    if (canEdit || !showInactive) return this;
    return InventoryListFilterState(
      stockFilter: stockFilter,
      showInactive: false,
      sortField: sortField,
      sortAscending: sortAscending,
    );
  }

  Map<String, dynamic> toJson() => {
    'stockFilter': stockFilter.name,
    'showInactive': showInactive,
    'sortField': sortField.name,
    'sortAscending': sortAscending,
  };

  factory InventoryListFilterState.fromJson(Map<String, dynamic> json) {
    return InventoryListFilterState(
      stockFilter: ProductStockFilter.values.firstWhere(
        (v) => v.name == json['stockFilter'],
        orElse: () => ProductStockFilter.all,
      ),
      showInactive: json['showInactive'] == true,
      sortField: InventorySortField.values.firstWhere(
        (v) => v.name == json['sortField'],
        orElse: () => InventorySortField.name,
      ),
      sortAscending: json['sortAscending'] is bool
          ? json['sortAscending'] as bool
          : true,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is InventoryListFilterState &&
            other.stockFilter == stockFilter &&
            other.showInactive == showInactive &&
            other.sortField == sortField &&
            other.sortAscending == sortAscending;
  }

  @override
  int get hashCode =>
      Object.hash(stockFilter, showInactive, sortField, sortAscending);
}

enum BillListStatusFilter { all, paid, partial, due }

enum BillListSortField { date, amount, customer }

class BillListFilterState {
  const BillListFilterState({
    this.status = BillListStatusFilter.all,
    this.periodQuery,
    this.customFromMs,
    this.customToMs,
    this.sortField = BillListSortField.date,
    this.sortAscending = false,
  });

  static const defaults = BillListFilterState();

  final BillListStatusFilter status;

  /// Encoded preset query value (`today`, `7d`, `30d`, `month`, `bsMonth`,
  /// `bsLastMonth`, `bsFy`, `bsLastFy`, `custom`), or `null` for all dates.
  final String? periodQuery;

  /// Inclusive custom calendar dates stored as UTC midnight millis when
  /// [periodQuery] == `'custom'`.
  final int? customFromMs;
  final int? customToMs;

  final BillListSortField sortField;
  final bool sortAscending;

  bool get hasDateFilter => periodQuery != null && periodQuery!.isNotEmpty;

  bool get isDefault =>
      status == BillListStatusFilter.all &&
      !hasDateFilter &&
      sortField == BillListSortField.date &&
      !sortAscending;

  int get activeCount {
    var count = 0;
    if (status != BillListStatusFilter.all) count++;
    if (hasDateFilter) count++;
    if (sortField != BillListSortField.date || sortAscending) count++;
    return count;
  }

  Map<String, dynamic> toJson() => {
    'status': status.name,
    'periodQuery': periodQuery,
    'customFromMs': customFromMs,
    'customToMs': customToMs,
    'sortField': sortField.name,
    'sortAscending': sortAscending,
  };

  factory BillListFilterState.fromJson(Map<String, dynamic> json) {
    final periodRaw = json['periodQuery'];
    final customFromRaw = json['customFromMs'];
    final customToRaw = json['customToMs'];
    final periodQuery = periodRaw is String && periodRaw.isNotEmpty
        ? periodRaw
        : null;
    final customFromMs = customFromRaw is int ? customFromRaw : null;
    final customToMs = customToRaw is int ? customToRaw : null;
    final validPeriod =
        periodQuery == 'custom' && (customFromMs == null || customToMs == null)
        ? null
        : periodQuery;
    return BillListFilterState(
      status: BillListStatusFilter.values.firstWhere(
        (v) => v.name == json['status'],
        orElse: () => BillListStatusFilter.all,
      ),
      periodQuery: validPeriod,
      customFromMs: validPeriod == 'custom' ? customFromMs : null,
      customToMs: validPeriod == 'custom' ? customToMs : null,
      sortField: BillListSortField.values.firstWhere(
        (v) => v.name == json['sortField'],
        orElse: () => BillListSortField.date,
      ),
      sortAscending: json['sortAscending'] is bool
          ? json['sortAscending'] as bool
          : false,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is BillListFilterState &&
            other.status == status &&
            other.periodQuery == periodQuery &&
            other.customFromMs == customFromMs &&
            other.customToMs == customToMs &&
            other.sortField == sortField &&
            other.sortAscending == sortAscending;
  }

  @override
  int get hashCode => Object.hash(
    status,
    periodQuery,
    customFromMs,
    customToMs,
    sortField,
    sortAscending,
  );
}

enum CustomerListSortField { name, balance, date }

class CustomerListFilterState {
  const CustomerListFilterState({
    this.balanceFilter = CustomerBalanceFilter.all,
    this.sortField = CustomerListSortField.name,
    this.sortAscending = true,
  });

  static const defaults = CustomerListFilterState();

  final CustomerBalanceFilter balanceFilter;
  final CustomerListSortField sortField;
  final bool sortAscending;

  bool get isDefault =>
      balanceFilter == CustomerBalanceFilter.all &&
      sortField == CustomerListSortField.name &&
      sortAscending;

  int get activeCount {
    var count = 0;
    if (balanceFilter != CustomerBalanceFilter.all) count++;
    if (sortField != CustomerListSortField.name || !sortAscending) count++;
    return count;
  }

  Map<String, dynamic> toJson() => {
    'balanceFilter': balanceFilter.name,
    'sortField': sortField.name,
    'sortAscending': sortAscending,
  };

  factory CustomerListFilterState.fromJson(Map<String, dynamic> json) {
    return CustomerListFilterState(
      balanceFilter: CustomerBalanceFilter.values.firstWhere(
        (v) => v.name == json['balanceFilter'],
        orElse: () => CustomerBalanceFilter.all,
      ),
      sortField: CustomerListSortField.values.firstWhere(
        (v) => v.name == json['sortField'],
        orElse: () => CustomerListSortField.name,
      ),
      sortAscending: json['sortAscending'] is bool
          ? json['sortAscending'] as bool
          : true,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CustomerListFilterState &&
            other.balanceFilter == balanceFilter &&
            other.sortField == sortField &&
            other.sortAscending == sortAscending;
  }

  @override
  int get hashCode => Object.hash(balanceFilter, sortField, sortAscending);
}

class OrderListFilterState {
  const OrderListFilterState({this.staffFilterName = 'needsAction'});

  static const defaults = OrderListFilterState();

  final String staffFilterName;

  bool get isDefault => staffFilterName == 'needsAction';

  int get activeCount => isDefault ? 0 : 1;

  Map<String, dynamic> toJson() => {'staffFilter': staffFilterName};

  factory OrderListFilterState.fromJson(Map<String, dynamic> json) {
    final raw = json['staffFilter'];
    const allowed = {'needsAction', 'received', 'billed', 'all'};
    return OrderListFilterState(
      staffFilterName: raw is String && allowed.contains(raw)
          ? raw
          : 'needsAction',
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is OrderListFilterState &&
            other.staffFilterName == staffFilterName;
  }

  @override
  int get hashCode => staffFilterName.hashCode;
}

/// Persists list filter states per `(businessId, memberId, role, listKey)`.
class SavedFiltersStore {
  const SavedFiltersStore();

  static const inventoryKey = 'inventory';
  static const billsKey = 'bills';
  static const customersKey = 'customers';
  static const ordersKey = 'orders';

  String _storageKey(FilterScope scope, String listKey) =>
      '${scope.keyPrefix}::$listKey';

  Future<Map<String, dynamic>?> loadMap(
    FilterScope? scope,
    String listKey,
  ) async {
    if (scope == null || !scope.isValid) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey(scope, listKey));
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveMap(
    FilterScope? scope,
    String listKey,
    Map<String, dynamic> data,
  ) async {
    if (scope == null || !scope.isValid) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey(scope, listKey), jsonEncode(data));
    } catch (_) {
      // Best-effort preference persistence must never break list UX.
    }
  }

  Future<void> clear(FilterScope? scope, String listKey) async {
    if (scope == null || !scope.isValid) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey(scope, listKey));
    } catch (_) {}
  }

  Future<void> clearAllForScope(FilterScope? scope) async {
    if (scope == null || !scope.isValid) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefix = '${scope.keyPrefix}::';
      for (final key in prefs.getKeys().toList()) {
        if (key.startsWith(prefix)) {
          await prefs.remove(key);
        }
      }
    } catch (_) {}
  }

  Future<InventoryListFilterState> loadInventory(
    FilterScope? scope, {
    required bool canEdit,
  }) async {
    final map = await loadMap(scope, inventoryKey);
    if (map == null) return InventoryListFilterState.defaults;
    return InventoryListFilterState.fromJson(
      map,
    ).sanitizeForRole(canEdit: canEdit);
  }

  Future<void> saveInventory(
    FilterScope? scope,
    InventoryListFilterState state,
  ) async {
    if (state.isDefault) {
      await clear(scope, inventoryKey);
    } else {
      await saveMap(scope, inventoryKey, state.toJson());
    }
  }

  Future<BillListFilterState> loadBills(FilterScope? scope) async {
    final map = await loadMap(scope, billsKey);
    if (map == null) return BillListFilterState.defaults;
    return BillListFilterState.fromJson(map);
  }

  Future<void> saveBills(FilterScope? scope, BillListFilterState state) async {
    if (state.isDefault) {
      await clear(scope, billsKey);
    } else {
      await saveMap(scope, billsKey, state.toJson());
    }
  }

  Future<CustomerListFilterState> loadCustomers(FilterScope? scope) async {
    // Warehouse must never access customer financial filters.
    if (scope == null || !scope.role.canViewCustomerBalance) {
      return CustomerListFilterState.defaults;
    }
    final map = await loadMap(scope, customersKey);
    if (map == null) return CustomerListFilterState.defaults;
    return CustomerListFilterState.fromJson(map);
  }

  Future<void> saveCustomers(
    FilterScope? scope,
    CustomerListFilterState state,
  ) async {
    if (scope == null || !scope.role.canViewCustomerBalance) return;
    if (state.isDefault) {
      await clear(scope, customersKey);
    } else {
      await saveMap(scope, customersKey, state.toJson());
    }
  }

  Future<OrderListFilterState> loadOrders(FilterScope? scope) async {
    final map = await loadMap(scope, ordersKey);
    if (map == null) return OrderListFilterState.defaults;
    return OrderListFilterState.fromJson(map);
  }

  Future<void> saveOrders(
    FilterScope? scope,
    OrderListFilterState state,
  ) async {
    if (state.isDefault) {
      await clear(scope, ordersKey);
    } else {
      await saveMap(scope, ordersKey, state.toJson());
    }
  }
}

final savedFiltersStoreProvider = Provider<SavedFiltersStore>(
  (ref) => const SavedFiltersStore(),
);
