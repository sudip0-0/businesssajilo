import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/report_range.dart';
import '../../data/repositories/reports_repository.dart';
import '../../domain/enums.dart';
import '../../domain/models/dues_aging_report.dart';
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
