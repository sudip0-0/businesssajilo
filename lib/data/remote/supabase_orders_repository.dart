import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../domain/enums.dart';
import '../../domain/models/order.dart';
import '../repositories/orders_repository.dart';

class SupabaseOrdersRepository implements OrdersRepository {
  SupabaseOrdersRepository(this._client);

  final SupabaseClient? _client;

  static const _listSelectStaff = '*, customers(shop_name), order_items(id)';
  static const _listSelectOwn = '*, order_items(id)';
  static const _detailSelect =
      '*, customers(shop_name), order_items(*, products(name, name_np, unit, image_url))';

  @override
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

  @override
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

  @override
  Future<List<Order>> fulfillmentQueue({int offset = 0, int? limit}) async {
    return listForStaff(
      statuses: [OrderStatus.confirmed, OrderStatus.packed],
      offset: offset,
      limit: limit,
    );
  }

  @override
  Future<int> pendingCount() async {
    final client = _requireClient();
    return client.from('orders').count(CountOption.exact).inFilter('status', [
      OrderStatus.placed.name,
      OrderStatus.quoted.name,
      OrderStatus.accepted.name,
    ]);
  }

  @override
  Future<int> openQuotesCount() async {
    final client = _requireClient();
    return client
        .from('orders')
        .count(CountOption.exact)
        .eq('status', OrderStatus.quoted.name);
  }

  @override
  Future<int> ownOrderCount() async {
    final client = _requireClient();
    return client.from('orders').count(CountOption.exact);
  }

  @override
  Future<int> fulfillmentActiveCount() async {
    final client = _requireClient();
    return client.from('orders').count(CountOption.exact).inFilter('status', [
      OrderStatus.confirmed.name,
      OrderStatus.packed.name,
    ]);
  }

  @override
  Future<Order> get(String id) async {
    final client = _requireClient();
    final row = await client
        .from('orders')
        .select(_detailSelect)
        .eq('id', id)
        .single();
    return mapOrderRow(row);
  }

  @override
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

  @override
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
