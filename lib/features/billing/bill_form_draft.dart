import '../../core/utils/bill_totals.dart';
import '../../core/utils/money.dart';
import '../../data/repositories/bills_repository.dart';
import '../../domain/models/bill.dart';
import '../../domain/models/product.dart';
import 'bill_draft_line.dart';

/// Shared bill form draft state used by mobile and web UIs.
class BillFormDraft {
  BillFormDraft({
    this.customerId,
    this.guestName,
    String billDiscountText = '',
  }) {
    this.billDiscountText = billDiscountText;
  }

  final List<BillDraftLine> lines = [];
  String _billDiscountText = '';
  int _billDiscount = 0;
  String get billDiscountText => _billDiscountText;
  set billDiscountText(String text) {
    _billDiscountText = text;
    if (text.trim().isEmpty) {
      _billDiscount = 0;
      return;
    }
    final parsed = parseNpr(text);
    if (parsed != null && parsed.value >= 0) _billDiscount = parsed.value;
  }

  bool get billDiscountInputValid {
    if (billDiscountText.trim().isEmpty) return true;
    final parsed = parseNpr(billDiscountText);
    return parsed != null && parsed.value >= 0;
  }

  String? customerId;

  /// Optional walk-in name for the bill only (not a customers row).
  String? guestName;

  int get itemsTotal => itemsTotalPaisa(lines.map((l) => l.lineTotal));

  int? get tryItemsTotal {
    final lineTotals = <int>[];
    for (final line in lines) {
      final total = line.tryLineTotal;
      if (total == null) return null;
      lineTotals.add(total);
    }
    return tryItemsTotalPaisa(lineTotals);
  }

  int get billDiscount => _billDiscount;

  int get grandTotal =>
      grandTotalPaisa(itemsTotal: itemsTotal, billDiscountPaisa: billDiscount);

  int? get tryGrandTotal {
    final items = tryItemsTotal;
    if (items == null) return null;
    return tryGrandTotalPaisa(
      itemsTotal: items,
      billDiscountPaisa: billDiscount,
    );
  }

  int get taxableAmount => itemsTotal - billDiscount;

  void loadFromBill(Bill bill, Iterable<Product> catalog) {
    lines.clear();
    final byId = {for (final product in catalog) product.id: product};
    for (final item in bill.items) {
      if (item.productId.isEmpty) continue;
      final product =
          byId[item.productId] ??
          Product(
            id: item.productId,
            businessId: bill.businessId,
            name: item.nameSnapshot,
            unit: 'piece',
            referencePrice: item.rate,
            isActive: false,
          );
      lines.add(
        BillDraftLine(
          product: product,
          qty: item.qty,
          rate: item.rate,
          discount: item.discount,
        ),
      );
    }
    customerId = bill.customerId;
    guestName = bill.customerId == null ? bill.customerShopName : null;
    billDiscountText = formatNpr(Paisa(bill.discount), showSymbol: false);
  }

  /// Merges [product] into an existing line or appends a new one.
  void addProduct(Product product) {
    final index = lines.indexWhere((l) => l.product.id == product.id);
    if (index >= 0) {
      lines[index].setQty(lines[index].qty + 1);
    } else {
      lines.add(BillDraftLine.fromProduct(product));
    }
  }

  void removeLineAt(int index) {
    if (index < 0 || index >= lines.length) return;
    lines.removeAt(index);
  }

  void updateQty(int index, int qty) {
    if (index < 0 || index >= lines.length) return;
    lines[index].setQty(qty);
  }

  void updateRate(int index, int rate) {
    if (index < 0 || index >= lines.length) return;
    lines[index].rate = rate < 0 ? 0 : rate;
  }

  void updateDiscount(int index, int discount) {
    if (index < 0 || index >= lines.length) return;
    lines[index].discount = discount;
  }

  List<BillLineInput> toLineInputs() {
    return [
      for (final line in lines)
        BillLineInput(
          productId: line.product.id,
          nameSnapshot: line.product.name,
          qty: line.qty,
          rate: line.rate,
          discount: line.discount,
          lineTotal: line.lineTotal,
        ),
    ];
  }
}
