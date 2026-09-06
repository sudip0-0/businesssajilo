import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../domain/enums.dart';
import '../../domain/models/order.dart';
import '../repositories/orders_repository.dart';
import 'supabase_provider.dart';

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
    final client = requireSupabaseClient(_client);
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
    final client = requireSupabaseClient(_client);
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
  Future<int> pendingCount() async {
    final client = requireSupabaseClient(_client);
    return client
        .from('orders')
        .count(CountOption.exact)
        .eq('status', OrderStatus.placed.name);
  }

  @override
  Future<int> ownOrderCount() async {
    final client = requireSupabaseClient(_client);
    return client.from('orders').count(CountOption.exact);
  }

  @override
  Future<Order> get(String id) async {
    final client = requireSupabaseClient(_client);
    final row = await client
        .from('orders')
        .select(_detailSelect)
        .eq('id', id)
        .single();
    return mapOrderRow(row);
  }

  @override
  Future<BillingOrderDraft?> billingDraftFromOrder(String orderId) async {
    final client = requireSupabaseClient(_client);
    final result = await client.rpc<dynamic>(
      'billing_draft_from_order',
      params: {'p_order_id': orderId},
    );
    return mapBillingOrderDraft(result);
  }

  @override
  Future<Order> placeOrder({
    String? id,
    required String customerId,
    required List<OrderLineInput> lines,
    String? note,
  }) async {
    final client = requireSupabaseClient(_client);
    final orderId = id ?? const Uuid().v4();
    await client.rpc(
      'place_order',
      params: {
        'p': {
          'id': orderId,
          'customer_id': customerId,
          'customer_note': note,
          'items': lines
              .map((line) => {'product_id': line.productId, 'qty': line.qty})
              .toList(),
        },
      },
    );

    return get(orderId);
  }

  @override
  Future<Order> updateStatus(String id, OrderStatus status) async {
    final client = requireSupabaseClient(_client);
    try {
      await client.from('orders').update({'status': status.name}).eq('id', id);
    } on PostgrestException catch (e) {
      throw OrderStatusException(e.message);
    }
    return get(id);
  }
}
