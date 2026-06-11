/// Pure bill total calculations — all amounts in paisa.
int lineTotalPaisa({
  required int qty,
  required int ratePaisa,
  int discountPaisa = 0,
}) {
  final gross = qty * ratePaisa;
  return gross - discountPaisa;
}

int itemsTotalPaisa(Iterable<int> lineTotals) =>
    lineTotals.fold(0, (sum, v) => sum + v);

int grandTotalPaisa({
  required int itemsTotal,
  int billDiscountPaisa = 0,
}) =>
    itemsTotal - billDiscountPaisa;
