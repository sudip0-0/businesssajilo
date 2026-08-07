import 'package:businesssajilo/core/l10n/app_localizations.dart';
import 'package:businesssajilo/domain/models/sales_period_point.dart';
import 'package:businesssajilo/domain/models/top_customer_row.dart';
import 'package:businesssajilo/domain/models/top_product_row.dart';
import 'package:businesssajilo/features/reports/providers.dart';
import 'package:businesssajilo/features/reports/report_period.dart';
import 'package:businesssajilo/web/features/reports/web_sales_report_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('WebSalesReportPage shows KPIs and top lists', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // Must match WebSalesReportPage default (fromQuery(null) → last7Days).
    final period = ReportPeriod.fromQuery(null);
    final prev = period.previousEqualLength;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          salesDailyRangeProvider(period).overrideWith(
            (ref) async => [
              SalesPeriodPoint(
                saleDate: period.from,
                billCount: 2,
                totalSales: 50000,
              ),
            ],
          ),
          salesDailyRangeProvider(prev).overrideWith((ref) async => const []),
          topProductsRangeProvider(period).overrideWith(
            (ref) async => [
              const TopProductRow(
                productId: 'p1',
                nameSnapshot: 'Cola',
                qtySold: 5,
                revenue: 25000,
              ),
            ],
          ),
          topCustomersRangeProvider(period).overrideWith(
            (ref) async => [
              const TopCustomerRow(
                customerId: 'c1',
                shopName: 'Ram Store',
                billCount: 2,
                revenue: 50000,
              ),
            ],
          ),
          billsInRangeProvider(
            BillsRangeQuery(period: period),
          ).overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: WebSalesReportPage()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Sales summary'), findsWidgets);
    expect(find.text('Cola'), findsOneWidget);
    expect(find.text('Ram Store'), findsOneWidget);
    expect(find.text('NET SALES'), findsOneWidget);
  });
}
