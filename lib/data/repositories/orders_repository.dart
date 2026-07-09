import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../domain/enums.dart';
import '../../domain/models/order.dart';
import '../../domain/models/order_item.dart';
import '../remote/supabase_provider.dart';

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepository(ref.watch(supabaseClientProvider));
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

class OrdersRepository {
  OrdersRepository(this._client);

  final SupabaseClient? _client;

  static const _listSelectStaff = '*, customers(shop_name), order_items(id)';
  static const _listSelectOwn = '*, order_items(id)';
  static const _detailSelect =
      '*, customers(shop_name), order_items(*, products(name, name_np, unit, image_url))';

  Future<List<Order>> listForStaff({
    List<OrderStatus>? statuses,
    int offset = 0,
    int? limit,
  }) async {
    final client = _requireClient();
    var query = client.from('orders').select(_listSelectStaff);
    if (statuses != null && statuses.isNotEmpty) {
      query = query.inFilter('status', statuses.map((s) => s.name).toList());
    }
    var ordered = query.order('created_at', ascending: false);
    if (limit != null) {
      ordered = ordered.range(offset, offset + limit - 1);
    }
    final rows = await ordered;
    return (rows as List).map(mapOrderRow).toList();
  }

  Future<List<Order>> listOwn({int offset = 0, int? limit}) async {
    final client = _requireClient();
    var query = client
        .from('orders')
        .select(_listSelectOwn)
        .order('created_at', ascending: false);
    if (limit != null) {
      query = query.range(offset, offset + limit - 1);
    }
    final rows = await query;
    return (rows as List).map(mapOrderRow).toList();
  }

  Future<List<Order>> fulfillmentQueue({int offset = 0, int? limit}) async {
    return listForStaff(
      statuses: [OrderStatus.confirmed, OrderStatus.packed],
      offset: offset,
      limit: limit,
    );
  }

  Future<int> pendingCount() async {
    final client = _requireClient();
    return client.from('orders').count(CountOption.exact).inFilter('status', [
      OrderStatus.placed.name,
      OrderStatus.quoted.name,
      OrderStatus.accepted.name,
    ]);
  }

  Future<int> openQuotesCount() async {
    final client = _requireClient();
    return client
        .from('orders')
        .count(CountOption.exact)
        .eq('status', OrderStatus.quoted.name);
  }

  Future<int> ownOrderCount() async {
    final client = _requireClient();
    return client.from('orders').count(CountOption.exact);
  }

  Future<int> fulfillmentActiveCount() async {
    final client = _requireClient();
    return client.from('orders').count(CountOption.exact).inFilter('status', [
      OrderStatus.confirmed.name,
      OrderStatus.packed.name,
    ]);
  }

  Future<Order> get(String id) async {
    final client = _requireClient();
    final row = await client
        .from('orders')
        .select(_detailSelect)
        .eq('id', id)
        .single();
    return mapOrderRow(row);
  }

  Future<Order> placeOrder({
    required String customerId,
    required List<OrderLineInput> lines,
    String? note,
  }) async {
    final client = _requireClient();
    final orderId = const Uuid().v4();

    await client.from('orders').insert({
      'id': orderId,
      'customer_id': customerId,
      'status': OrderStatus.placed.name,
      'customer_note': ?note,
    });

    if (lines.isNotEmpty) {
      await client
          .from('order_items')
          .insert(
            lines
                .map(
                  (line) => {
                    'id': const Uuid().v4(),
                    'order_id': orderId,
                    'product_id': line.productId,
                    'qty': line.qty,
                  },
                )
                .toList(),
          );
    }

    return get(orderId);
  }

  Future<Order> updateStatus(String id, OrderStatus status) async {
    final client = _requireClient();
    try {
      await client.from('orders').update({'status': status.name}).eq('id', id);
    } on PostgrestException catch (e) {
      throw OrderStatusException(e.message);
    }
    return get(id);
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) throw Exception('Supabase not configured');
    return client;
  }
}
