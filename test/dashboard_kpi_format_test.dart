import 'package:businesssajilo/domain/models/owner_dashboard_stats.dart';
import 'package:businesssajilo/features/reports/dashboard/dashboard_kpi_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('hides trend percent when today sales are zero', () {
    const stats = OwnerDashboardStats(
      todaySales: 0,
      yesterdaySales: 10000,
      totalDues: 0,
      lowStockCount: 0,
      pendingOrders: 0,
    );
    expect(formatDashboardTrendPercent(stats), isNull);
  });

  test('formats percent when today has sales', () {
    const stats = OwnerDashboardStats(
      todaySales: 20000,
      yesterdaySales: 10000,
      totalDues: 0,
      lowStockCount: 0,
      pendingOrders: 0,
    );
    expect(formatDashboardTrendPercent(stats), '100%');
  });
}
