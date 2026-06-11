import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/report_range.dart';
import '../../domain/models/aging_customer_row.dart';
import '../../domain/models/dues_aging_report.dart';
import '../../domain/models/sales_period_point.dart';
import '../../domain/models/stock_valuation_row.dart';
import '../../domain/models/top_customer_row.dart';
import '../../domain/models/top_product_row.dart';
import '../remote/supabase_provider.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository(ref.watch(supabaseClientProvider));
});

class ReportsRepository {
  ReportsRepository(this._client);

  final SupabaseClient? _client;

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
    return (rows as List).map(_mapSalesDaily).toList();
  }

  Future<List<TopProductRow>> topProducts({
    required DateTime from,
    required DateTime to,
    int limit = 10,
  }) async {
    final client = _requireClient();
    final rows = await client.rpc('report_top_products_range', params: {
      'p_from': _dateOnly(from),
      'p_to': _dateOnly(to),
      'p_limit': limit,
    });
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

  Future<List<TopCustomerRow>> topCustomers({
    required DateTime from,
    required DateTime to,
    int limit = 10,
  }) async {
    final client = _requireClient();
    final rows = await client.rpc('report_top_customers_range', params: {
      'p_from': _dateOnly(from),
      'p_to': _dateOnly(to),
      'p_limit': limit,
    });
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
      final customer = _mapAgingCustomer(row);
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

  Future<List<StockValuationRow>> stockValuation({bool lowStockOnly = false}) async {
    final client = _requireClient();
    var query = client.from('report_stock_valuation').select();
    if (lowStockOnly) {
      query = query.eq('is_low_stock', true);
    }
    final rows = await query.order('valuation', ascending: false);
    return (rows as List).map(_mapStockValuation).toList();
  }

  SalesPeriodPoint _mapSalesDaily(dynamic row) {
    final map = Map<String, dynamic>.from(row as Map);
    return SalesPeriodPoint(
      saleDate: DateTime.parse('${map['sale_date']}T00:00:00Z'),
      billCount: (map['bill_count'] as num?)?.toInt() ?? 0,
      totalSales: (map['total_sales'] as num?)?.toInt() ?? 0,
    );
  }

  AgingCustomerRow _mapAgingCustomer(dynamic row) {
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

  StockValuationRow _mapStockValuation(dynamic row) {
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

  // Report views use Asia/Kathmandu dates, so convert UTC instants to NPT
  // calendar dates.
  String _dateOnly(DateTime dt) => nptDateString(dt);

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) throw Exception('Supabase not configured');
    return client;
  }
}
