/// Aggregated owner-dashboard KPI values (amounts in paisa).
class OwnerDashboardStats {
  const OwnerDashboardStats({
    required this.todaySales,
    required this.yesterdaySales,
    required this.totalDues,
    required this.lowStockCount,
    required this.pendingOrders,
  });

  final int todaySales;
  final int yesterdaySales;
  final int totalDues;
  final int lowStockCount;
  final int pendingOrders;

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

  /// Percent change today vs yesterday (null when no baseline).
  double? get salesTrendPercent {
    if (yesterdaySales == 0) return todaySales > 0 ? 100.0 : null;
    return ((todaySales - yesterdaySales) / yesterdaySales) * 100;
  }
}
