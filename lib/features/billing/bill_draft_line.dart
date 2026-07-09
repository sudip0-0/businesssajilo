import '../../core/utils/bill_totals.dart';
import '../../domain/models/product.dart';

/// A mutable draft line on a bill form (mobile or web).
class BillDraftLine {
  BillDraftLine({
    required this.product,
    int qty = 1,
    int? rate,
    this.discount = 0,
  }) : qty = qty < 1 ? 1 : qty,
       rate = rate ?? product.referencePrice;

  factory BillDraftLine.fromProduct(Product product) =>
      BillDraftLine(product: product);

  final Product product;
  int qty;
  int rate;
  int discount;

  int get lineTotal =>
      lineTotalPaisa(qty: qty, ratePaisa: rate, discountPaisa: discount);

  bool get discountValid =>
      isValidLineDiscount(qty: qty, ratePaisa: rate, discountPaisa: discount);

  void setQty(int value) {
    qty = value < 1 ? 1 : value;
  }
}
