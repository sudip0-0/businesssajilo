import '../../core/utils/bill_totals.dart';
import '../../core/utils/money.dart';
import '../../data/repositories/bills_repository.dart';
import '../../domain/models/product.dart';
import 'bill_draft_line.dart';

/// Shared bill form draft state used by mobile and web UIs.
class BillFormDraft {
  BillFormDraft({this.customerId, this.billDiscountText = ''});

  final List<BillDraftLine> lines = [];
  String billDiscountText;
  String? customerId;

  int get itemsTotal => itemsTotalPaisa(lines.map((l) => l.lineTotal));

  int get billDiscount => parseNpr(billDiscountText)?.value ?? 0;

  int get grandTotal =>
      grandTotalPaisa(itemsTotal: itemsTotal, billDiscountPaisa: billDiscount);

  int get taxableAmount => itemsTotal - billDiscount;

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
