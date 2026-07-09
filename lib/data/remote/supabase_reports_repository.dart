import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/report_range.dart';
import '../../domain/models/aging_customer_row.dart';
import '../../domain/models/dues_aging_report.dart';
import '../../domain/models/owner_dashboard_stats.dart';
import '../../domain/models/sales_period_point.dart';
import '../../domain/models/stock_valuation_row.dart';
import '../../domain/models/top_customer_row.dart';
import '../../domain/models/top_product_row.dart';
import '../repositories/reports_repository.dart';

class SupabaseReportsRepository implements ReportsRepository {
  SupabaseReportsRepository(this._client);

  final SupabaseClient? _client;

  @override
  Future<List<SalesPeriodPoint>> salesDaily({
    required DateTime from,
    required DateTime to,
  }) async {
    final client = _requireClient();
    final rows = await client
        .from('report_sales_daily')
        .select()
        .gte('sale_date', _dateOnly(from))
        .lt('sale_date', _dateOnly(to))
        .order('sale_date', ascending: true);
    return (rows as List).map(mapSalesDailyRow).toList();
  }

  @override
  Future<int> netSalesForNptDate(DateTime utcInstant) async {
    final client = _requireClient();
    final day = nptDateString(utcInstant);
    final rows = await client
        .from('report_sales_daily')
        .select('total_sales')
        .eq('sale_date', day);
    var total = 0;
    for (final row in rows as List) {
      total += ((row as Map)['total_sales'] as num?)?.toInt() ?? 0;
    }
    return total;
  }

  @override
  Future<List<TopProductRow>> topProducts({
    required DateTime from,
    required DateTime to,
    int limit = 10,
  }) async {
    final client = _requireClient();
    final rows = await client.rpc(
      'report_top_products_range',
      params: {
        'p_from': _dateOnly(from),
        'p_to': _dateOnly(to),
        'p_limit': limit,
      },
    );
    return (rows as List).map((row) {
      final map = Map<String, dynamic>.from(row as Map);
      return TopProductRow(
        productId: map['product_id'] as String,
        nameSnapshot: map['name_snapshot'] as String,
        qtySold: (map['qty_sold'] as num?)?.toInt() ?? 0,
        revenue: (map['revenue'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  @override
  Future<List<TopCustomerRow>> topCustomers({
    required DateTime from,
    required DateTime to,
    int limit = 10,
  }) async {
    final client = _requireClient();
    final rows = await client.rpc(
      'report_top_customers_range',
      params: {
        'p_from': _dateOnly(from),
        'p_to': _dateOnly(to),
        'p_limit': limit,
      },
    );
    return (rows as List).map((row) {
      final map = Map<String, dynamic>.from(row as Map);
      return TopCustomerRow(
        customerId: map['customer_id'] as String,
        shopName: map['shop_name'] as String,
        billCount: (map['bill_count'] as num?)?.toInt() ?? 0,
        revenue: (map['revenue'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  @override
  Future<DuesAgingReport> duesAging() async {
    final client = _requireClient();
    final rows = await client
        .from('customer_dues_aging')
        .select()
        .order('balance_due', ascending: false);
    var b0 = 0;
    var b31 = 0;
    var b60 = 0;
    final customers = <AgingCustomerRow>[];
    for (final row in rows as List) {
      final customer = mapAgingCustomerRow(row);
      customers.add(customer);
      switch (customer.bucket) {
        case '0_30':
          b0 += customer.balanceDue;
        case '31_60':
          b31 += customer.balanceDue;
        case '60_plus':
          b60 += customer.balanceDue;
      }
    }
    return DuesAgingReport(
      bucket0to30: b0,
      bucket31to60: b31,
      bucket60plus: b60,
      customers: customers,
    );
  }

  @override
  Future<List<StockValuationRow>> stockValuation({
    bool lowStockOnly = false,
  }) async {
    final client = _requireClient();
    var query = client.from('report_stock_valuation').select();
    if (lowStockOnly) {
      query = query.eq('is_low_stock', true);
    }
    final rows = await query.order('valuation', ascending: false);
    return (rows as List).map(mapStockValuationRow).toList();
  }

  @override
  Future<OwnerDashboardStats> ownerDashboardStats() async {
    final client = _requireClient();
    final raw = await client.rpc('owner_dashboard_stats');
    final map = raw is Map
        ? Map<String, dynamic>.from(raw)
        : Map<String, dynamic>.from((raw as List).first as Map);
    return OwnerDashboardStats.fromJson(map);
  }

  // Report views use Asia/Kathmandu dates, so convert UTC instants to NPT
  // calendar dates.
  String _dateOnly(DateTime dt) => nptDateString(dt);

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) throw Exception('Supabase not configured');
    return client;
  }
}
