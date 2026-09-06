import '../../core/utils/bill_totals.dart';
import '../../core/utils/money.dart';
import '../../domain/models/product.dart';

/// A mutable draft line on a bill form (mobile or web).
class BillDraftLine {
  BillDraftLine({
    required this.product,
    int qty = 1,
    int? rate,
    int discount = 0,
  }) : qty = qty < 1 ? 1 : qty,
       _rate = rate ?? product.referencePrice,
       _discount = discount;

  factory BillDraftLine.fromProduct(Product product) =>
      BillDraftLine(product: product);

  final Product product;
  int qty;
  int _rate;
  int _discount;
  String? _rateText;
  String? _discountText;

  int get rate => _rate;
  set rate(int value) {
    _rate = value;
    _rateText = null;
  }

  int get discount => _discount;
  set discount(int value) {
    _discount = value;
    _discountText = null;
  }

  String get rateText => _rateText ?? formatNpr(Paisa(rate), showSymbol: false);
  String get discountText =>
      _discountText ??
      (discount == 0 ? '' : formatNpr(Paisa(discount), showSymbol: false));
  bool get rateInputValid {
    final parsed = parseNpr(rateText);
    return parsed != null && parsed.value >= 0;
  }

  bool get discountInputValid {
    if (discountText.trim().isEmpty) return true;
    final parsed = parseNpr(discountText);
    return parsed != null && parsed.value >= 0;
  }

  void setRateText(String text) {
    _rateText = text;
    final parsed = parseNpr(text);
    if (parsed != null && parsed.value >= 0) _rate = parsed.value;
  }

  void setDiscountText(String text) {
    _discountText = text;
    if (text.trim().isEmpty) {
      _discount = 0;
      return;
    }
    final parsed = parseNpr(text);
    if (parsed != null && parsed.value >= 0) _discount = parsed.value;
  }

  int get lineTotal =>
      lineTotalPaisa(qty: qty, ratePaisa: rate, discountPaisa: discount);

  int? get tryLineTotal =>
      tryLineTotalPaisa(qty: qty, ratePaisa: rate, discountPaisa: discount);

  bool get discountValid =>
      isValidLineDiscount(qty: qty, ratePaisa: rate, discountPaisa: discount);

  void setQty(int value) {
    qty = value < 1 ? 1 : value;
  }
}
