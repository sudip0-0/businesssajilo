import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/bill_totals.dart';
import '../../domain/enums.dart';
import '../../domain/models/order.dart';
import '../../domain/models/order_item.dart';
import '../remote/supabase_orders_repository.dart';
import '../remote/supabase_provider.dart';
import 'bills_repository.dart';

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return SupabaseOrdersRepository(ref.watch(supabaseClientProvider));
});

/// Raised when the server rejects an order status transition. The UI layer
/// maps this to a localized 'invalid status change' message.
class OrderStatusException implements Exception {
  OrderStatusException(this.message);

  final String message;

  @override
  String toString() => message;
}

class OrderLineInput {
  const OrderLineInput({required this.productId, required this.qty});

  final String productId;
  final int qty;
}

/// Maps a PostgREST order row (staff or own list / detail) into [Order].
/// Supports both full nested product payloads and light `order_items(id)` lists.
Order mapOrderRow(dynamic row) {
  final map = Map<String, dynamic>.from(row as Map);
  final customer = map.remove('customers');
  if (customer is Map) {
    map['customer_shop_name'] = customer['shop_name'];
  }
  final itemsRaw = map.remove('order_items');
  final order = Order.fromJson(map);
  if (itemsRaw is List) {
    final items = itemsRaw.map((raw) {
      final itemMap = Map<String, dynamic>.from(raw as Map);
      final product = itemMap.remove('products');
      if (product is Map) {
        // Prefer joined product fields; keep snapshotted columns as fallback
        // (customers cannot SELECT products via RLS).
        itemMap['product_name'] = product['name'] ?? itemMap['product_name'];
        itemMap['product_name_np'] =
            product['name_np'] ?? itemMap['product_name_np'];
        itemMap['unit'] = product['unit'] ?? itemMap['unit'];
        itemMap['image_url'] = product['image_url'] ?? itemMap['image_url'];
      }
      // Light list select only returns item ids — fill required fields.
      itemMap.putIfAbsent('order_id', () => order.id);
      itemMap.putIfAbsent('product_id', () => '');
      itemMap.putIfAbsent('qty', () => 0);
      return OrderItem.fromJson(itemMap);
    }).toList();
    return order.copyWith(items: items);
  }
  return order;
}

abstract class OrdersRepository {
  Future<List<Order>> listForStaff({
    List<OrderStatus>? statuses,
    int offset = 0,
    int? limit,
  });
  Future<List<Order>> listOwn({int offset = 0, int? limit});
  Future<int> pendingCount();
  Future<int> ownOrderCount();
  Future<Order> get(String id);

  /// Staff billing-draft read. Default is unused so test fakes can keep
  /// mapping via [get] + accepted quotes. Production uses the RPC.
  Future<BillingOrderDraft?> billingDraftFromOrder(String orderId) async =>
      null;

  Future<Order> placeOrder({
    String? id,
    required String customerId,
    required List<OrderLineInput> lines,
    String? note,
  });
  Future<Order> updateStatus(String id, OrderStatus status);
}

/// Identity-only order billing prefill. No quote history or customer finance.
class BillingOrderDraft {
  const BillingOrderDraft({
    required this.orderId,
    required this.customerId,
    required this.lines,
    required this.source,
    this.shopName,
  });

  final String orderId;
  final String customerId;
  final String? shopName;
  final List<BillLineInput> lines;
  final String source;
}

BillingOrderDraft mapBillingOrderDraft(dynamic raw) {
  if (raw is! Map) {
    throw const FormatException('Invalid billing draft');
  }
  final map = Map<String, dynamic>.from(raw);
  final orderId = map['order_id'];
  final customerId = map['customer_id'];
  final source = map['source'];
  final linesRaw = map['lines'];
  if (orderId is! String ||
      orderId.trim().isEmpty ||
      customerId is! String ||
      customerId.trim().isEmpty ||
      source is! String ||
      (source != 'accepted_quote' && source != 'order_items') ||
      linesRaw is! List) {
    throw const FormatException('Invalid billing draft');
  }
  if (map.containsKey('opening_balance') ||
      map.containsKey('balance_due') ||
      map.containsKey('quotes') ||
      map.containsKey('response_comment')) {
    throw const FormatException('Billing draft exposed restricted fields');
  }
  final lines = linesRaw.map(_mapBillingDraftLine).toList();
  final shop = map['shop_name'];
  return BillingOrderDraft(
    orderId: orderId,
    customerId: customerId,
    shopName: shop is String && shop.trim().isNotEmpty ? shop : null,
    lines: lines,
    source: source,
  );
}

BillLineInput _mapBillingDraftLine(dynamic raw) {
  if (raw is! Map) {
    throw const FormatException('Invalid billing draft line');
  }
  final map = Map<String, dynamic>.from(raw);
  final productId = map['product_id'];
  final name = map['name_snapshot'];
  final qty = map['qty'];
  final rate = map['rate'];
  final discount = map['discount'] ?? 0;
  if (productId is! String ||
      productId.trim().isEmpty ||
      name is! String ||
      qty is! num ||
      !qty.isFinite ||
      qty != qty.roundToDouble() ||
      qty <= 0 ||
      rate is! num ||
      !rate.isFinite ||
      rate != rate.roundToDouble() ||
      rate < 0 ||
      discount is! num ||
      !discount.isFinite ||
      discount != discount.roundToDouble() ||
      discount < 0) {
    throw const FormatException('Invalid billing draft line');
  }
  final qtyInt = qty.toInt();
  final rateInt = rate.toInt();
  final discountInt = discount.toInt();
  final lineTotal = lineTotalPaisa(
    qty: qtyInt,
    ratePaisa: rateInt,
    discountPaisa: discountInt,
  );
  final acknowledged = map['line_total'];
  if (acknowledged is num && acknowledged.toInt() != lineTotal) {
    throw const FormatException('Invalid billing draft line total');
  }
  return BillLineInput(
    productId: productId,
    nameSnapshot: name,
    qty: qtyInt,
    rate: rateInt,
    discount: discountInt,
    lineTotal: lineTotal,
  );
}
