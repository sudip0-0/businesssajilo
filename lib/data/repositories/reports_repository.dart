import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/aging_customer_row.dart';
import '../../domain/models/dues_aging_report.dart';
import '../../domain/models/owner_dashboard_stats.dart';
import '../../domain/models/sales_period_point.dart';
import '../../domain/models/stock_valuation_row.dart';
import '../../domain/models/top_customer_row.dart';
import '../../domain/models/top_product_row.dart';
import '../remote/supabase_provider.dart';
import '../remote/supabase_reports_repository.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return SupabaseReportsRepository(ref.watch(supabaseClientProvider));
});

abstract class ReportsRepository {
  Future<List<SalesPeriodPoint>> salesDaily({
    required DateTime from,
    required DateTime to,
  });

  /// Net sales (bills minus credit notes) for a single NPT calendar day.
  Future<int> netSalesForNptDate(DateTime utcInstant);

  Future<List<TopProductRow>> topProducts({
    required DateTime from,
    required DateTime to,
    int limit = 10,
  });

  Future<List<TopCustomerRow>> topCustomers({
    required DateTime from,
    required DateTime to,
    int limit = 10,
  });

  Future<DuesAgingReport> duesAging();

  Future<List<StockValuationRow>> stockValuation({bool lowStockOnly = false});

  /// Single-roundtrip owner dashboard KPIs (see `owner_dashboard_stats` RPC).
  Future<OwnerDashboardStats> ownerDashboardStats();
}

/// Shared mappers for report view / RPC rows (used by the Supabase impl).
SalesPeriodPoint mapSalesDailyRow(dynamic row) {
  final map = Map<String, dynamic>.from(row as Map);
  return SalesPeriodPoint(
    saleDate: DateTime.parse('${map['sale_date']}T00:00:00Z'),
    billCount: (map['bill_count'] as num?)?.toInt() ?? 0,
    totalSales: (map['total_sales'] as num?)?.toInt() ?? 0,
  );
}

AgingCustomerRow mapAgingCustomerRow(dynamic row) {
  final map = Map<String, dynamic>.from(row as Map);
  return AgingCustomerRow(
    customerId: map['customer_id'] as String,
    shopName: map['shop_name'] as String,
    balanceDue: (map['balance_due'] as num?)?.toInt() ?? 0,
    oldestDueAt: DateTime.parse(map['oldest_due_at'] as String),
    ageDays: (map['age_days'] as num?)?.toInt() ?? 0,
    bucket: map['bucket'] as String,
  );
}

StockValuationRow mapStockValuationRow(dynamic row) {
  final map = Map<String, dynamic>.from(row as Map);
  return StockValuationRow(
    productId: map['product_id'] as String,
    name: map['name'] as String,
    stockCached: (map['stock_cached'] as num?)?.toInt() ?? 0,
    costPrice: (map['cost_price'] as num?)?.toInt() ?? 0,
    valuation: (map['valuation'] as num?)?.toInt() ?? 0,
    isLowStock: map['is_low_stock'] as bool? ?? false,
  );
}
