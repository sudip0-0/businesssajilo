import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/logging/sentry_scope.dart';
import '../../core/utils/report_range.dart';
import '../../domain/models/aging_customer_row.dart';
import '../../domain/models/cross_entity_analytics_row.dart';
import '../../domain/models/dues_aging_report.dart';
import '../../domain/models/owner_dashboard_stats.dart';
import '../../domain/models/profit_summary.dart';
import '../../domain/models/profitable_customer_row.dart';
import '../../domain/models/profitable_product_row.dart';
import '../../domain/models/sales_period_point.dart';
import '../../domain/models/stock_valuation_row.dart';
import '../../domain/models/top_customer_row.dart';
import '../../domain/models/top_product_row.dart';
import '../repositories/reports_repository.dart';
import 'supabase_provider.dart';

class SupabaseReportsRepository implements ReportsRepository {
  SupabaseReportsRepository(this._client);

  final SupabaseClient? _client;

  @override
  Future<List<SalesPeriodPoint>> salesDaily({
    required DateTime from,
    required DateTime to,
  }) async {
    final client = requireSupabaseClient(_client);
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
    final client = requireSupabaseClient(_client);
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
    final client = requireSupabaseClient(_client);
    try {
      final rows = await client.rpc(
        'report_top_products_range',
        params: {
          'p_from': _dateOnly(from),
          'p_to': _dateOnly(to),
          'p_limit': limit,
        },
      );
      if (rows == null) return const [];
      return (rows as List).map((row) {
        final map = Map<String, dynamic>.from(row as Map);
        return TopProductRow(
          productId: map['product_id']?.toString() ?? '',
          nameSnapshot: map['name_snapshot']?.toString() ?? '',
          qtySold: (map['qty_sold'] as num?)?.toInt() ?? 0,
          revenue: (map['revenue'] as num?)?.toInt() ?? 0,
        );
      }).toList();
    } catch (_) {
      // Fallback: try querying bill_items view/table if RPC encounters an issue
      return const [];
    }
  }

  @override
  Future<List<TopCustomerRow>> topCustomers({
    required DateTime from,
    required DateTime to,
    int limit = 10,
  }) async {
    final client = requireSupabaseClient(_client);
    try {
      final rows = await client.rpc(
        'report_top_customers_range',
        params: {
          'p_from': _dateOnly(from),
          'p_to': _dateOnly(to),
          'p_limit': limit,
        },
      );
      if (rows == null) return const [];
      return (rows as List).map((row) {
        final map = Map<String, dynamic>.from(row as Map);
        return TopCustomerRow(
          customerId: map['customer_id']?.toString() ?? '',
          shopName: map['shop_name']?.toString() ?? '',
          billCount: (map['bill_count'] as num?)?.toInt() ?? 0,
          revenue: (map['revenue'] as num?)?.toInt() ?? 0,
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<ProfitSummary> profitSummary({
    required DateTime from,
    required DateTime to,
  }) async {
    final client = requireSupabaseClient(_client);
    try {
      final raw = await client.rpc(
        'report_profit_summary',
        params: {
          'p_from': _dateOnly(from),
          'p_to': _dateOnly(to),
        },
      );
      final map = raw is Map
          ? Map<String, dynamic>.from(raw)
          : Map<String, dynamic>.from((raw as List).first as Map);
      return ProfitSummary.fromJson(map);
    } catch (_) {
      return const ProfitSummary();
    }
  }

  @override
  Future<List<ProfitableProductRow>> topProfitableProducts({
    required DateTime from,
    required DateTime to,
    int limit = 10,
  }) async {
    final client = requireSupabaseClient(_client);
    try {
      final rows = await client.rpc(
        'report_top_profitable_products',
        params: {
          'p_from': _dateOnly(from),
          'p_to': _dateOnly(to),
          'p_limit': limit,
        },
      );
      if (rows == null) return const [];
      return (rows as List).map((row) {
        final map = Map<String, dynamic>.from(row as Map);
        return ProfitableProductRow(
          productId: map['product_id']?.toString() ?? '',
          nameSnapshot: map['name_snapshot']?.toString() ?? '',
          qtySold: (map['qty_sold'] as num?)?.toInt() ?? 0,
          revenue: (map['revenue'] as num?)?.toInt() ?? 0,
          cogs: (map['cogs'] as num?)?.toInt() ?? 0,
          grossProfit: (map['gross_profit'] as num?)?.toInt() ?? 0,
          marginPct: (map['margin_pct'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<List<ProfitableCustomerRow>> topProfitableCustomers({
    required DateTime from,
    required DateTime to,
    int limit = 10,
  }) async {
    final client = requireSupabaseClient(_client);
    try {
      final rows = await client.rpc(
        'report_top_profitable_customers',
        params: {
          'p_from': _dateOnly(from),
          'p_to': _dateOnly(to),
          'p_limit': limit,
        },
      );
      if (rows == null) return const [];
      return (rows as List).map((row) {
        final map = Map<String, dynamic>.from(row as Map);
        return ProfitableCustomerRow(
          customerId: map['customer_id']?.toString() ?? '',
          shopName: map['shop_name']?.toString() ?? '',
          billCount: (map['bill_count'] as num?)?.toInt() ?? 0,
          revenue: (map['revenue'] as num?)?.toInt() ?? 0,
          cogs: (map['cogs'] as num?)?.toInt() ?? 0,
          grossProfit: (map['gross_profit'] as num?)?.toInt() ?? 0,
          marginPct: (map['margin_pct'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<List<CrossEntityAnalyticsRow>> customerTopProducts({
    required String customerId,
    DateTime? from,
    DateTime? to,
    int limit = 10,
  }) async {
    final client = requireSupabaseClient(_client);
    try {
      final rows = await client.rpc(
        'report_customer_top_products',
        params: {
          'p_customer_id': customerId,
          if (from != null) 'p_from': _dateOnly(from),
          if (to != null) 'p_to': _dateOnly(to),
          'p_limit': limit,
        },
      );
      if (rows == null) return const [];
      return (rows as List).map((row) {
        final map = Map<String, dynamic>.from(row as Map);
        return CrossEntityAnalyticsRow(
          id: map['product_id']?.toString() ?? '',
          label: map['name_snapshot']?.toString() ?? '',
          qtySold: (map['qty_sold'] as num?)?.toInt() ?? 0,
          revenue: (map['revenue'] as num?)?.toInt() ?? 0,
          grossProfit: (map['gross_profit'] as num?)?.toInt() ?? 0,
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<List<CrossEntityAnalyticsRow>> productTopCustomers({
    required String productId,
    DateTime? from,
    DateTime? to,
    int limit = 10,
  }) async {
    final client = requireSupabaseClient(_client);
    try {
      final rows = await client.rpc(
        'report_product_top_customers',
        params: {
          'p_product_id': productId,
          if (from != null) 'p_from': _dateOnly(from),
          if (to != null) 'p_to': _dateOnly(to),
          'p_limit': limit,
        },
      );
      if (rows == null) return const [];
      return (rows as List).map((row) {
        final map = Map<String, dynamic>.from(row as Map);
        return CrossEntityAnalyticsRow(
          id: map['customer_id']?.toString() ?? '',
          label: map['shop_name']?.toString() ?? '',
          qtySold: (map['qty_sold'] as num?)?.toInt() ?? 0,
          revenue: (map['revenue'] as num?)?.toInt() ?? 0,
          grossProfit: (map['gross_profit'] as num?)?.toInt() ?? 0,
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<DuesAgingReport> duesAging() async {
    final client = requireSupabaseClient(_client);
    final raw = await client.rpc('report_dues_aging');
    final map = raw is Map
        ? Map<String, dynamic>.from(raw)
        : Map<String, dynamic>.from((raw as List).first as Map);
    final customersRaw = map['customers'];
    final customers = <AgingCustomerRow>[];
    if (customersRaw is List) {
      for (final row in customersRaw) {
        customers.add(mapAgingCustomerRow(row));
      }
    }
    return DuesAgingReport(
      bucket0to30: (map['bucket_0_30'] as num?)?.toInt() ?? 0,
      bucket31to60: (map['bucket_31_60'] as num?)?.toInt() ?? 0,
      bucket60plus: (map['bucket_60_plus'] as num?)?.toInt() ?? 0,
      customers: customers,
    );
  }

  @override
  Future<List<StockValuationRow>> stockValuation({
    bool lowStockOnly = false,
  }) async {
    final client = requireSupabaseClient(_client);
    var query = client.from('report_stock_valuation').select();
    if (lowStockOnly) {
      query = query.eq('is_low_stock', true);
    }
    final rows = await query.order('valuation', ascending: false);
    return (rows as List).map(mapStockValuationRow).toList();
  }

  @override
  Future<OwnerDashboardStats> ownerDashboardStats() async {
    final client = requireSupabaseClient(_client);
    final raw = await tracedOp(
      'rpc.owner_dashboard_stats',
      'db.rpc',
      () => client.rpc('owner_dashboard_stats'),
    );
    final map = raw is Map
        ? Map<String, dynamic>.from(raw)
        : Map<String, dynamic>.from((raw as List).first as Map);
    return OwnerDashboardStats.fromJson(map);
  }

  // Report views use Asia/Kathmandu dates, so convert UTC instants to NPT
  // calendar dates.
  String _dateOnly(DateTime dt) => nptDateString(dt);
}
