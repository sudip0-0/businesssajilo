import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/bill_totals.dart';
import '../../data/repositories/bills_repository.dart';
import '../../data/repositories/orders_repository.dart';
import '../../data/repositories/products_repository.dart';
import '../../domain/models/bill.dart';
import '../../domain/models/order.dart';
import '../../domain/models/order_item.dart';
import '../auth/providers/auth_provider.dart';
import 'bill_payment_result.dart';
import 'invalidate_billing.dart';

class BillFromOrderDraft {
  const BillFromOrderDraft({
    required this.lines,
    required this.itemsTotal,
    this.discount = 0,
  });

  final List<BillLineInput> lines;
  final int itemsTotal;
  final int discount;

  int get grandTotal => itemsTotal - discount;

  bool get isEmpty => lines.isEmpty;

  BillFromOrderDraft copyWithLines(List<BillLineInput> lines) {
    return BillFromOrderDraft(
      lines: lines,
      itemsTotal: itemsTotalPaisa(lines.map((l) => l.lineTotal)),
      discount: discount,
    );
  }
}

/// Maps order items + product reference prices into bill lines (pure).
BillFromOrderDraft billFromOrderDraftFromItems(
  List<OrderItem> items, {
  required Map<String, int> ratesByProductId,
}) {
  final lines = items.map((item) {
    final rate = ratesByProductId[item.productId] ?? 0;
    final discount = 0;
    final lineTotal = lineTotalPaisa(
      qty: item.qty,
      ratePaisa: rate,
      discountPaisa: discount,
    );
    return BillLineInput(
      productId: item.productId,
      nameSnapshot: item.productName ?? '—',
      qty: item.qty,
      rate: rate,
      discount: discount,
      lineTotal: lineTotal,
    );
  }).toList();
  return BillFromOrderDraft(
    lines: lines,
    itemsTotal: itemsTotalPaisa(lines.map((l) => l.lineTotal)),
  );
}

BillLineInput billLineWithEdits(
  BillLineInput line, {
  int? qty,
  int? rate,
  int? discount,
}) {
  final nextQty = qty ?? line.qty;
  final nextRate = rate ?? line.rate;
  final nextDiscount = discount ?? line.discount;
  return BillLineInput(
    productId: line.productId,
    nameSnapshot: line.nameSnapshot,
    qty: nextQty,
    rate: nextRate,
    discount: nextDiscount,
    lineTotal: lineTotalPaisa(
      qty: nextQty,
      ratePaisa: nextRate,
      discountPaisa: nextDiscount,
    ),
  );
}

/// Loads order items and product reference prices into a bill draft.
Future<BillFromOrderDraft?> loadBillFromOrderDraft(
  Ref ref,
  String orderId,
) async {
  final Order order = await ref.read(ordersRepositoryProvider).get(orderId);
  if (order.items.isEmpty) return null;

  final productsRepo = ref.read(productsRepositoryProvider);
  final rates = <String, int>{};
  for (final item in order.items) {
    if (rates.containsKey(item.productId)) continue;
    try {
      final product = await productsRepo.get(item.productId);
      rates[item.productId] = product.referencePrice;
    } catch (_) {
      rates[item.productId] = 0;
    }
  }
  return billFromOrderDraftFromItems(order.items, ratesByProductId: rates);
}

Future<Bill> saveBillFromOrder(
  Ref ref, {
  required String orderId,
  required String customerId,
  required BillFromOrderDraft draft,
  required BillPaymentResult payment,
}) async {
  final memberId = ref.read(authProvider).value?.member?.id;
  if (memberId == null) {
    throw StateError('Not authenticated');
  }
  if (draft.lines.isEmpty) {
    throw StateError('No bill lines');
  }
  final bill = await ref
      .read(billsRepositoryProvider)
      .createFromOrder(
        orderId: orderId,
        customerId: customerId,
        createdByMemberId: memberId,
        status: payment.status,
        itemsTotal: draft.itemsTotal,
        discount: draft.discount,
        grandTotal: draft.grandTotal,
        lines: draft.lines,
        paymentMethod: payment.paymentMethod,
        paymentRefNote: payment.paymentRefNote,
        paymentAmount: payment.paymentAmount,
      );
  invalidateAfterBillSaved(ref, customerId: customerId, orderId: orderId);
  return bill;
}
