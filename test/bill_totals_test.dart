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

  test('clampLineDiscountPaisa caps discount at line gross', () {
    expect(
      clampLineDiscountPaisa(qty: 2, ratePaisa: 5000, discountPaisa: 15000),
      10000,
    );
    expect(
      clampLineDiscountPaisa(qty: 2, ratePaisa: 5000, discountPaisa: -100),
      0,
    );
    expect(
      clampLineDiscountPaisa(qty: 2, ratePaisa: 5000, discountPaisa: 4000),
      4000,
    );
  });

  test('isValidLineDiscount bounds [0, qty*rate]', () {
    expect(isValidLineDiscount(qty: 2, ratePaisa: 5000, discountPaisa: 0), true);
    expect(
      isValidLineDiscount(qty: 2, ratePaisa: 5000, discountPaisa: 10000),
      true,
    );
    expect(
      isValidLineDiscount(qty: 2, ratePaisa: 5000, discountPaisa: 10001),
      false,
    );
    expect(
      isValidLineDiscount(qty: 2, ratePaisa: 5000, discountPaisa: -1),
      false,
    );
  });

  test('clamped discount never yields negative line total', () {
    final clamped =
        clampLineDiscountPaisa(qty: 3, ratePaisa: 1000, discountPaisa: 99999);
    expect(
      lineTotalPaisa(qty: 3, ratePaisa: 1000, discountPaisa: clamped),
      0,
    );
  });
}
