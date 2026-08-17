/// Aggregated owner-dashboard KPI values (amounts in paisa).
///
/// Individual fields may be null when the preferred RPC fails and a fallback
/// source also fails — UI should render "—" rather than a false zero.
class OwnerDashboardStats {
  const OwnerDashboardStats({
    required this.todaySales,
    required this.yesterdaySales,
    required this.totalDues,
    required this.lowStockCount,
    required this.pendingOrders,
    this.pendingSyncSales = 0,
  });

  final int? todaySales;
  final int? yesterdaySales;
  final int? totalDues;
  final int? lowStockCount;
  final int? pendingOrders;

  /// Local uncommitted (pending/failed) bill totals for today. Never included
  /// in [todaySales] — those are confirmed server/synced figures only.
  final int pendingSyncSales;

  factory OwnerDashboardStats.fromJson(Map<String, dynamic> json) {
    int asInt(Object? v) => (v as num?)?.toInt() ?? 0;
    return OwnerDashboardStats(
      todaySales: asInt(json['today_sales']),
      yesterdaySales: asInt(json['yesterday_sales']),
      totalDues: asInt(json['total_dues']),
      lowStockCount: asInt(json['low_stock_count']),
      pendingOrders: asInt(json['pending_orders']),
      pendingSyncSales: asInt(json['pending_sync_sales']),
    );
  }

  OwnerDashboardStats copyWith({
    int? todaySales,
    int? yesterdaySales,
    int? totalDues,
    int? lowStockCount,
    int? pendingOrders,
    int? pendingSyncSales,
  }) {
    return OwnerDashboardStats(
      todaySales: todaySales ?? this.todaySales,
      yesterdaySales: yesterdaySales ?? this.yesterdaySales,
      totalDues: totalDues ?? this.totalDues,
      lowStockCount: lowStockCount ?? this.lowStockCount,
      pendingOrders: pendingOrders ?? this.pendingOrders,
      pendingSyncSales: pendingSyncSales ?? this.pendingSyncSales,
    );
  }

  /// Percent change today vs yesterday (null when either side is missing).
  double? get salesTrendPercent {
    final today = todaySales;
    final yesterday = yesterdaySales;
    if (today == null || yesterday == null) return null;
    if (yesterday == 0) return today > 0 ? 100.0 : null;
    return ((today - yesterday) / yesterday) * 100;
  }
}
