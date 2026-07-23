import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/report_range.dart';
import '../../core/logging/app_log.dart';
import '../../data/repositories/bills_repository.dart';
import '../../data/repositories/orders_repository.dart';
import '../../data/repositories/payments_repository.dart';
import '../../data/repositories/products_repository.dart';
import '../../data/repositories/reports_repository.dart';
import '../../domain/enums.dart';
import '../../domain/models/dues_aging_report.dart';
import '../../domain/models/owner_dashboard_stats.dart';
import '../../domain/models/sales_period_point.dart';
import '../../domain/models/stock_valuation_row.dart';
import '../../domain/models/top_customer_row.dart';
import '../../domain/models/top_product_row.dart';

final salesDailyProvider = FutureProvider.autoDispose
    .family<List<SalesPeriodPoint>, ReportRange>((ref, range) {
      final window = dateRangeFor(range);
      return ref
          .watch(reportsRepositoryProvider)
          .salesDaily(from: window.from, to: window.to);
    });

final topProductsProvider = FutureProvider.autoDispose
    .family<List<TopProductRow>, ReportRange>((ref, range) {
      final window = dateRangeFor(range);
      return ref
          .watch(reportsRepositoryProvider)
          .topProducts(from: window.from, to: window.to);
    });

final topCustomersProvider = FutureProvider.autoDispose
    .family<List<TopCustomerRow>, ReportRange>((ref, range) {
      final window = dateRangeFor(range);
      return ref
          .watch(reportsRepositoryProvider)
          .topCustomers(from: window.from, to: window.to);
    });

final duesAgingProvider = FutureProvider.autoDispose<DuesAgingReport>((ref) {
  return ref.watch(reportsRepositoryProvider).duesAging();
});

final stockValuationProvider = FutureProvider.autoDispose
    .family<List<StockValuationRow>, bool>((ref, lowStockOnly) {
      return ref
          .watch(reportsRepositoryProvider)
          .stockValuation(lowStockOnly: lowStockOnly);
    });

final last7DaySalesProvider =
    FutureProvider.autoDispose<List<SalesPeriodPoint>>((ref) {
      final window = dateRangeFor(ReportRange.last7Days);
      return ref
          .watch(reportsRepositoryProvider)
          .salesDaily(from: window.from, to: window.to);
    });

/// Owner dashboard KPI tiles — prefers `owner_dashboard_stats` RPC; on failure
/// (e.g. offline staff mobile) falls back to existing local-capable methods.
/// Individual fallbacks that also fail become null (UI shows "—", not a false 0).
final ownerDashboardStatsProvider =
    FutureProvider.autoDispose<OwnerDashboardStats>((ref) async {
      try {
        return await ref.watch(reportsRepositoryProvider).ownerDashboardStats();
      } catch (e, st) {
        AppLog.warn('owner_dashboard_stats RPC fallback', e, st);
        Future<int?> safe(String metric, Future<int> Function() load) async {
          try {
            return await load();
          } catch (inner, innerSt) {
            AppLog.warn('owner_dashboard_stats partial fallback: $metric', inner, innerSt);
            return null;
          }
        }

        final bills = ref.read(billsRepositoryProvider);
        final payments = ref.read(paymentsRepositoryProvider);
        final products = ref.read(productsRepositoryProvider);
        final orders = ref.read(ordersRepositoryProvider);
        final results = await Future.wait([
          safe('todaySales', bills.todaysSales),
          safe('yesterdaySales', bills.yesterdaysSales),
          safe('totalDues', payments.totalDues),
          safe('lowStockCount', products.lowStockCount),
          safe('pendingOrders', orders.pendingCount),
        ]);
        return OwnerDashboardStats(
          todaySales: results[0],
          yesterdaySales: results[1],
          totalDues: results[2],
          lowStockCount: results[3],
          pendingOrders: results[4],
        );
      }
    });
