import 'money.dart';

/// Pure bill total calculations — all amounts in paisa.
///
/// Multiplications and running totals stay inside the portable exact-integer
/// range shared by native Dart and JavaScript ([maxExactPaisa]). Overflow is
/// never silently rounded.
int? tryLineGrossPaisa({required int qty, required int ratePaisa}) {
  if (qty < 0 || ratePaisa < 0) return null;
  final product = BigInt.from(qty) * BigInt.from(ratePaisa);
  if (product > BigInt.from(maxExactPaisa)) return null;
  return product.toInt();
}

int lineGrossPaisa({required int qty, required int ratePaisa}) {
  final gross = tryLineGrossPaisa(qty: qty, ratePaisa: ratePaisa);
  if (gross == null) {
    throw ArgumentError('Line gross exceeds portable exact integer range');
  }
  return gross;
}

int lineTotalPaisa({
  required int qty,
  required int ratePaisa,
  int discountPaisa = 0,
}) {
  return lineGrossPaisa(qty: qty, ratePaisa: ratePaisa) - discountPaisa;
}

int lineDiscountsTotalPaisa(Iterable<int> lineDiscounts) =>
    itemsTotalPaisa(lineDiscounts);

/// Caps a line discount so it never exceeds the line gross (qty * rate),
/// and never goes negative.
int clampLineDiscountPaisa({
  required int qty,
  required int ratePaisa,
  required int discountPaisa,
}) {
  final gross = lineGrossPaisa(qty: qty, ratePaisa: ratePaisa);
  if (discountPaisa < 0) return 0;
  if (discountPaisa > gross) return gross;
  return discountPaisa;
}

/// True when the discount is within [0, qty * rate] and that product is exact.
bool isValidLineDiscount({
  required int qty,
  required int ratePaisa,
  required int discountPaisa,
}) {
  final gross = tryLineGrossPaisa(qty: qty, ratePaisa: ratePaisa);
  return gross != null && discountPaisa >= 0 && discountPaisa <= gross;
}

int? tryItemsTotalPaisa(Iterable<int> lineTotals) {
  var sum = BigInt.zero;
  final limit = BigInt.from(maxExactPaisa);
  for (final value in lineTotals) {
    sum += BigInt.from(value);
    if (sum > limit || sum < -limit) return null;
  }
  return sum.toInt();
}

int itemsTotalPaisa(Iterable<int> lineTotals) {
  final total = tryItemsTotalPaisa(lineTotals);
  if (total == null) {
    throw ArgumentError('Items total exceeds portable exact integer range');
  }
  return total;
}

int grandTotalPaisa({required int itemsTotal, int billDiscountPaisa = 0}) =>
    itemsTotal - billDiscountPaisa;

/// Remaining unpaid amount on a bill. Never negative.
int remainingDuePaisa({required int grandTotal, required int amountReceived}) {
  final left = grandTotal - amountReceived;
  return left < 0 ? 0 : left;
}

/// Prorates a bill line's discount onto a partial return quantity.
///
/// Uses integer floor division to match `create_credit_note` in Postgres:
/// `floor(originalDiscount * returnedQty / originalQty)`.
int proratedLineDiscountPaisa({
  required int originalDiscountPaisa,
  required int originalQty,
  required int returnedQty,
}) {
  if (originalQty <= 0 || returnedQty <= 0) return 0;
  if (originalDiscountPaisa <= 0) return 0;
  final prorated =
      (BigInt.from(originalDiscountPaisa) * BigInt.from(returnedQty)) ~/
      BigInt.from(originalQty);
  if (prorated < BigInt.zero) return 0;
  if (prorated > BigInt.from(maxExactPaisa)) return maxExactPaisa;
  return prorated.toInt();
}
