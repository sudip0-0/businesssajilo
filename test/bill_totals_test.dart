import 'package:businesssajilo/core/utils/bill_totals.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('line and grand totals in paisa', () {
    expect(
      lineTotalPaisa(qty: 2, ratePaisa: 5000, discountPaisa: 500),
      9500,
    );

    final items = [
      lineTotalPaisa(qty: 1, ratePaisa: 10000),
      lineTotalPaisa(qty: 3, ratePaisa: 2000, discountPaisa: 1000),
    ];
    expect(itemsTotalPaisa(items), 15000);
    expect(
      grandTotalPaisa(itemsTotal: 15000, billDiscountPaisa: 2000),
      13000,
    );
  });
}
