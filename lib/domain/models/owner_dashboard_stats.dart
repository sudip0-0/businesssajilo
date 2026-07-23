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
  });

  final int? todaySales;
  final int? yesterdaySales;
  final int? totalDues;
  final int? lowStockCount;
  final int? pendingOrders;

  factory OwnerDashboardStats.fromJson(Map<String, dynamic> json) {
    int asInt(Object? v) => (v as num?)?.toInt() ?? 0;
    return OwnerDashboardStats(
      todaySales: asInt(json['today_sales']),
      yesterdaySales: asInt(json['yesterday_sales']),
      totalDues: asInt(json['total_dues']),
      lowStockCount: asInt(json['low_stock_count']),
      pendingOrders: asInt(json['pending_orders']),
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
