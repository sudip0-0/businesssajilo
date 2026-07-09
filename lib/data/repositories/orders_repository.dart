import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/enums.dart';
import '../../domain/models/order.dart';
import '../../domain/models/order_item.dart';
import '../remote/supabase_orders_repository.dart';
import '../remote/supabase_provider.dart';

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
        itemMap['product_name'] = product['name'];
        itemMap['product_name_np'] = product['name_np'];
        itemMap['unit'] = product['unit'];
        itemMap['image_url'] = product['image_url'];
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
  Future<List<Order>> fulfillmentQueue({int offset = 0, int? limit});
  Future<int> pendingCount();
  Future<int> openQuotesCount();
  Future<int> ownOrderCount();
  Future<int> fulfillmentActiveCount();
  Future<Order> get(String id);
  Future<Order> placeOrder({
    required String customerId,
    required List<OrderLineInput> lines,
    String? note,
  });
  Future<Order> updateStatus(String id, OrderStatus status);
}
