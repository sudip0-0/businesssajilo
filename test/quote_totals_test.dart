import 'package:businesssajilo/core/utils/bill_totals.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('quote line total matches bill totals helper', () {
    expect(
      lineTotalPaisa(qty: 5, ratePaisa: 5000, discountPaisa: 1000),
      24000,
    );
  });

  test('quote grand total sums line totals', () {
    final lines = [
      lineTotalPaisa(qty: 2, ratePaisa: 5000),
      lineTotalPaisa(qty: 3, ratePaisa: 4000, discountPaisa: 500),
    ];
    expect(itemsTotalPaisa(lines), 21500);
  });
}
