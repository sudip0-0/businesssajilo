import '../../data/repositories/bills_repository.dart';
import '../../data/repositories/products_repository.dart';
import '../../domain/models/bill.dart';
import '../../domain/models/product.dart';

/// Latest bill with line items. [BillsRepository.list] omits `bill_items`,
/// so this follows up with [BillsRepository.get] when needed.
Future<Bill?> fetchLatestBillWithItems(BillsRepository bills) async {
  final listed = await bills.list(limit: 1);
  if (listed.isEmpty) return null;
  final latest = listed.first;
  if (latest.items.isNotEmpty) return latest;
  return bills.get(latest.id);
}

/// Resolves live products for [bill] items (stock, active flag). Missing
/// catalog rows are omitted; [BillFormDraft.loadFromBill] fills those from
/// the item snapshot so the copy still has lines.
Future<List<Product>> productsForBillItems({
  required ProductsRepository products,
  required Bill bill,
}) async {
  final byId = <String, Product>{};
  for (final item in bill.items) {
    final id = item.productId;
    if (id.isEmpty || byId.containsKey(id)) continue;
    try {
      byId[id] = await products.get(id);
    } catch (_) {}
  }
  return byId.values.toList();
}
