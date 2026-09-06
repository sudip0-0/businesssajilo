import 'package:businesssajilo/core/utils/bill_totals.dart';
import 'package:businesssajilo/core/utils/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('line gross and line-discount sum stay separate from net total', () {
    expect(lineGrossPaisa(qty: 6, ratePaisa: 18500), 111000);
    expect(lineDiscountsTotalPaisa(const [5000, 2000, 0]), 7000);
    expect(
      lineGrossPaisa(qty: 6, ratePaisa: 18500) -
          lineDiscountsTotalPaisa(const [5000]),
      lineTotalPaisa(qty: 6, ratePaisa: 18500, discountPaisa: 5000),
    );
  });

  test('line and grand totals in paisa', () {
    expect(lineTotalPaisa(qty: 2, ratePaisa: 5000, discountPaisa: 500), 9500);

    final items = [
      lineTotalPaisa(qty: 1, ratePaisa: 10000),
      lineTotalPaisa(qty: 3, ratePaisa: 2000, discountPaisa: 1000),
    ];
    expect(itemsTotalPaisa(items), 15000);
    expect(grandTotalPaisa(itemsTotal: 15000, billDiscountPaisa: 2000), 13000);
    expect(remainingDuePaisa(grandTotal: 13000, amountReceived: 4000), 9000);
    expect(remainingDuePaisa(grandTotal: 1000, amountReceived: 1500), 0);
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
    expect(
      isValidLineDiscount(qty: 2, ratePaisa: 5000, discountPaisa: 0),
      true,
    );
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
    final clamped = clampLineDiscountPaisa(
      qty: 3,
      ratePaisa: 1000,
      discountPaisa: 99999,
    );
    expect(lineTotalPaisa(qty: 3, ratePaisa: 1000, discountPaisa: clamped), 0);
  });

  test('proratedLineDiscountPaisa floors partial return discount', () {
    // 10 units, NPR 100 line discount → return 1 → floor(100/10) = 10.
    expect(
      proratedLineDiscountPaisa(
        originalDiscountPaisa: 10000,
        originalQty: 10,
        returnedQty: 1,
      ),
      1000,
    );
    // Non-divisible: floor(100 * 1 / 3) = 33.
    expect(
      proratedLineDiscountPaisa(
        originalDiscountPaisa: 100,
        originalQty: 3,
        returnedQty: 1,
      ),
      33,
    );
    expect(
      proratedLineDiscountPaisa(
        originalDiscountPaisa: 100,
        originalQty: 3,
        returnedQty: 3,
      ),
      100,
    );
    expect(
      proratedLineDiscountPaisa(
        originalDiscountPaisa: 0,
        originalQty: 5,
        returnedQty: 2,
      ),
      0,
    );
  });

  test('quantity times rate stays inside the web exact-integer range', () {
    expect(lineGrossPaisa(qty: 1, ratePaisa: maxExactPaisa), maxExactPaisa);
    expect(tryLineGrossPaisa(qty: 2, ratePaisa: maxExactPaisa), isNull);
    expect(
      () => lineGrossPaisa(qty: 2, ratePaisa: maxExactPaisa),
      throwsArgumentError,
    );
    expect(
      isValidLineDiscount(qty: 2, ratePaisa: maxExactPaisa, discountPaisa: 0),
      isFalse,
    );
  });

  test('multi-line accumulation rejects totals past the web integer limit', () {
    expect(itemsTotalPaisa(const [maxExactPaisa, 0]), maxExactPaisa);
    expect(tryItemsTotalPaisa(const [maxExactPaisa, 1]), isNull);
    expect(
      () => itemsTotalPaisa(const [maxExactPaisa, 1]),
      throwsArgumentError,
    );
    expect(
      tryItemsTotalPaisa([maxExactPaisa ~/ 2 + 1, maxExactPaisa ~/ 2 + 1]),
      isNull,
    );
  });
}
