/// Pure bill total calculations — all amounts in paisa.
int lineTotalPaisa({
  required int qty,
  required int ratePaisa,
  int discountPaisa = 0,
}) {
  final gross = qty * ratePaisa;
  return gross - discountPaisa;
}

/// Caps a line discount so it never exceeds the line gross (qty * rate),
/// and never goes negative.
int clampLineDiscountPaisa({
  required int qty,
  required int ratePaisa,
  required int discountPaisa,
}) {
  final gross = qty * ratePaisa;
  if (discountPaisa < 0) return 0;
  if (discountPaisa > gross) return gross;
  return discountPaisa;
}

/// True when the discount is within [0, qty * rate].
bool isValidLineDiscount({
  required int qty,
  required int ratePaisa,
  required int discountPaisa,
}) =>
    discountPaisa >= 0 && discountPaisa <= qty * ratePaisa;

int itemsTotalPaisa(Iterable<int> lineTotals) =>
    lineTotals.fold(0, (sum, v) => sum + v);

int grandTotalPaisa({
  required int itemsTotal,
  int billDiscountPaisa = 0,
}) =>
    itemsTotal - billDiscountPaisa;
