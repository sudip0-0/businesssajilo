import '../../core/utils/money.dart';
import '../../domain/models/bill.dart';
import '../../domain/models/dues_aging_report.dart';
import '../../domain/models/ledger_entry.dart';
import '../../domain/models/sales_period_point.dart';
import '../../domain/models/stock_valuation_row.dart';
import '../../domain/models/top_customer_row.dart';
import '../../domain/models/top_product_row.dart';

List<List<String>> salesReportCsvRows({
  required List<SalesPeriodPoint> daily,
  required List<TopProductRow> topProducts,
  required List<TopCustomerRow> topCustomers,
}) {
  final rows = <List<String>>[
    ['Section', 'Label', 'Metric 1', 'Metric 2'],
  ];
  for (final point in daily) {
    rows.add([
      'Daily sales',
      point.saleDate.toIso8601String().split('T').first,
      '${point.billCount}',
      formatNpr(Paisa(point.totalSales), showPaisa: false),
    ]);
  }
  rows.add(['Top products', 'Product', 'Qty sold', 'Revenue']);
  for (final p in topProducts) {
    rows.add([
      'Top products',
      p.nameSnapshot,
      '${p.qtySold}',
      formatNpr(Paisa(p.revenue), showPaisa: false),
    ]);
  }
  rows.add(['Top customers', 'Customer', 'Bill count', 'Revenue']);
  for (final c in topCustomers) {
    rows.add([
      'Top customers',
      c.shopName,
      '${c.billCount}',
      formatNpr(Paisa(c.revenue), showPaisa: false),
    ]);
  }
  return rows;
}

List<List<String>> duesAgingCsvRows(DuesAgingReport report) {
  final rows = <List<String>>[
    ['Customer', 'Bucket', 'Amount due'],
  ];
  for (final customer in report.customers) {
    rows.add([
      customer.shopName,
      customer.bucket,
      formatNpr(Paisa(customer.balanceDue), showPaisa: false),
    ]);
  }
  return rows;
}

List<List<String>> stockValuationCsvRows(List<StockValuationRow> rows_) {
  final rows = <List<String>>[
    ['Product', 'Qty', 'Cost', 'Valuation', 'Low stock'],
  ];
  for (final row in rows_) {
    rows.add([
      row.name,
      '${row.stockCached}',
      formatNpr(Paisa(row.costPrice), showPaisa: false),
      formatNpr(Paisa(row.valuation), showPaisa: false),
      row.isLowStock ? 'Yes' : 'No',
    ]);
  }
  return rows;
}

List<List<String>> ledgerCsvRows(List<LedgerEntry> entries) {
  final rows = <List<String>>[
    ['Date', 'Type', 'Description', 'Debit', 'Credit', 'Balance'],
  ];
  for (final entry in entries) {
    rows.add([
      entry.occurredAt.toIso8601String(),
      entry.entryType,
      entry.description,
      formatNpr(Paisa(entry.debitPaisa), showPaisa: false),
      formatNpr(Paisa(entry.creditPaisa), showPaisa: false),
      formatNpr(Paisa(entry.runningBalance), showPaisa: false),
    ]);
  }
  return rows;
}

List<List<String>> todaysBillsCsvRows(List<Bill> bills) {
  final rows = <List<String>>[
    ['Bill no', 'Customer', 'Status', 'Grand total', 'Created at'],
  ];
  for (final bill in bills) {
    rows.add([
      bill.billNo,
      bill.customerShopName ?? 'Walk-in',
      bill.status.name,
      formatNpr(Paisa(bill.grandTotal), showPaisa: false),
      bill.createdAt?.toIso8601String() ?? '',
    ]);
  }
  return rows;
}
