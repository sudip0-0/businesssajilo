import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/bill_totals.dart';
import '../../data/repositories/bills_repository.dart';
import '../../data/repositories/orders_repository.dart';
import '../../data/repositories/products_repository.dart';
import '../../data/repositories/quotes_repository.dart';
import '../../domain/models/bill.dart';
import '../../domain/models/order.dart';
import '../../domain/models/order_item.dart';
import '../../domain/models/quote.dart';
import '../auth/providers/auth_provider.dart';
import 'bill_payment_result.dart';
import 'invalidate_billing.dart';

class BillFromOrderDraft {
  const BillFromOrderDraft({
    required this.lines,
    required this.itemsTotal,
    this.discount = 0,
    this.customerId,
    this.shopName,
  });

  final List<BillLineInput> lines;
  final int itemsTotal;
  final int discount;
  final String? customerId;
  final String? shopName;

  int get grandTotal => itemsTotal - discount;

  bool get isEmpty => lines.isEmpty;

  BillFromOrderDraft copyWithLines(List<BillLineInput> lines) {
    return BillFromOrderDraft(
      lines: lines,
      itemsTotal: itemsTotalPaisa(lines.map((l) => l.lineTotal)),
      discount: discount,
      customerId: customerId,
      shopName: shopName,
    );
  }

  BillFromOrderDraft copyWithCustomer(String? customerId, String? shopName) {
    return BillFromOrderDraft(
      lines: lines,
      itemsTotal: itemsTotal,
      discount: discount,
      customerId: customerId,
      shopName: shopName,
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

BillFromOrderDraft billFromAcceptedQuote(Quote quote) {
  if (quote.items.isEmpty) throw StateError('Accepted quote has no items');
  final lines = quote.items
      .map(
        (item) => BillLineInput(
          productId: item.productId,
          nameSnapshot: item.productName ?? '—',
          qty: item.qty,
          rate: item.rate,
          discount: item.discount,
          lineTotal: lineTotalPaisa(
            qty: item.qty,
            ratePaisa: item.rate,
            discountPaisa: item.discount,
          ),
        ),
      )
      .toList();
  return BillFromOrderDraft(
    lines: lines,
    itemsTotal: itemsTotalPaisa(lines.map((line) => line.lineTotal)),
  );
}

Future<BillFromOrderDraft?> loadBillFromOrderDraft(Ref ref, String orderId) =>
    loadBillFromOrderRepositories(
      orderId: orderId,
      orders: ref.read(ordersRepositoryProvider),
      quotes: ref.read(quotesRepositoryProvider),
      products: ref.read(productsRepositoryProvider),
    );

Future<BillFromOrderDraft?> loadBillFromOrderRepositories({
  required String orderId,
  required OrdersRepository orders,
  required QuotesRepository quotes,
  required ProductsRepository products,
}) async {
  final remote = await orders.billingDraftFromOrder(orderId);
  if (remote != null) {
    if (remote.lines.isEmpty) return null;
    return BillFromOrderDraft(
      lines: remote.lines,
      itemsTotal: itemsTotalPaisa(remote.lines.map((line) => line.lineTotal)),
      customerId: remote.customerId,
      shopName: remote.shopName,
    );
  }
  final Order order = await orders.get(orderId);
  final accepted = await quotes.latestAccepted(orderId);
  if (accepted != null) {
    return billFromAcceptedQuote(
      accepted,
    ).copyWithCustomer(order.customerId, order.customerShopName);
  }
  if (order.items.isEmpty) return null;
  final rates = <String, int>{};
  for (final item in order.items) {
    final product = await products.get(item.productId);
    rates[item.productId] = product.referencePrice;
  }
  return billFromOrderDraftFromItems(
    order.items,
    ratesByProductId: rates,
  ).copyWithCustomer(order.customerId, order.customerShopName);
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
