import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../domain/enums.dart';
import '../../domain/models/bill.dart';
import '../../domain/models/bill_item.dart';
import '../repositories/bills_repository.dart';
import '../repositories/payments_repository.dart';

class SupabaseBillsRepository implements BillsRepository {
  SupabaseBillsRepository(this._client, this._payments);

  final SupabaseClient? _client;
  final PaymentsRepository _payments;

  @override
  Future<List<Bill>> list() async {
    final client = _requireClient();
    final rows = await client
        .from('bills')
        .select('*, customers(shop_name)')
        .order('created_at', ascending: false);
    return (rows as List).map(_mapBillRow).toList();
  }

  @override
  Future<Bill> get(String id) async {
    final client = _requireClient();
    final row = await client
        .from('bills')
        .select('*, customers(shop_name), bill_items(*)')
        .eq('id', id)
        .single();
    return _mapBillRow(row);
  }

  @override
  Future<int> todaysSales() async {
    final client = _requireClient();
    final now = DateTime.now().toUtc();
    final start = DateTime.utc(now.year, now.month, now.day);
    final rows = await client
        .from('bills')
        .select('grand_total')
        .gte('created_at', start.toIso8601String());
    var total = 0;
    for (final row in rows as List) {
      total += ((row as Map)['grand_total'] as num?)?.toInt() ?? 0;
    }
    return total;
  }

  @override
  Future<int> todaysBillCount() async {
    final client = _requireClient();
    final now = DateTime.now().toUtc();
    final start = DateTime.utc(now.year, now.month, now.day);
    final rows = await client
        .from('bills')
        .select('id')
        .gte('created_at', start.toIso8601String());
    return (rows as List).length;
  }

  @override
  Future<Bill> create({
    required String createdByMemberId,
    String? customerId,
    required BillStatus status,
    required int itemsTotal,
    required int discount,
    required int grandTotal,
    required List<BillLineInput> lines,
    PaymentMethod paymentMethod = PaymentMethod.cash,
    String? paymentRefNote,
    int? paymentAmount,
  }) async {
    final client = _requireClient();
    final billId = const Uuid().v4();

    await client.from('bills').insert({
      'id': billId,
      'customer_id': ?customerId,
      'items_total': itemsTotal,
      'discount': discount,
      'grand_total': grandTotal,
      'status': status.name,
      'created_by': createdByMemberId,
    });

    if (lines.isNotEmpty) {
      await client.from('bill_items').insert(
            lines
                .map(
                  (line) => {
                    'id': const Uuid().v4(),
                    'bill_id': billId,
                    'product_id': line.productId,
                    'name_snapshot': line.nameSnapshot,
                    'qty': line.qty,
                    'rate': line.rate,
                    'discount': line.discount,
                    'line_total': line.lineTotal,
                  },
                )
                .toList(),
          );
    }

    if (customerId != null &&
        (status == BillStatus.paid || status == BillStatus.partial)) {
      final amount =
          status == BillStatus.paid ? grandTotal : (paymentAmount ?? 0);
      if (amount > 0) {
        await _payments.record(
          customerId: customerId,
          amount: amount,
          method: paymentMethod,
          refNote: paymentRefNote,
          billId: billId,
          receivedByMemberId: createdByMemberId,
        );
      }
    }

    return get(billId);
  }

  @override
  Future<Bill> createFromOrder({
    required String orderId,
    required String customerId,
    required String createdByMemberId,
    required BillStatus status,
    required int itemsTotal,
    required int discount,
    required int grandTotal,
    required List<BillLineInput> lines,
    PaymentMethod paymentMethod = PaymentMethod.cash,
    String? paymentRefNote,
    int? paymentAmount,
  }) async {
    final client = _requireClient();
    final billId = const Uuid().v4();

    await client.from('bills').insert({
      'id': billId,
      'customer_id': customerId,
      'order_id': orderId,
      'items_total': itemsTotal,
      'discount': discount,
      'grand_total': grandTotal,
      'status': status.name,
      'created_by': createdByMemberId,
    });

    if (lines.isNotEmpty) {
      await client.from('bill_items').insert(
            lines
                .map(
                  (line) => {
                    'id': const Uuid().v4(),
                    'bill_id': billId,
                    'product_id': line.productId,
                    'name_snapshot': line.nameSnapshot,
                    'qty': line.qty,
                    'rate': line.rate,
                    'discount': line.discount,
                    'line_total': line.lineTotal,
                  },
                )
                .toList(),
          );
    }

    if (status == BillStatus.paid || status == BillStatus.partial) {
      final amount =
          status == BillStatus.paid ? grandTotal : (paymentAmount ?? 0);
      if (amount > 0) {
        await _payments.record(
          customerId: customerId,
          amount: amount,
          method: paymentMethod,
          refNote: paymentRefNote,
          billId: billId,
          receivedByMemberId: createdByMemberId,
        );
      }
    }

    await client
        .from('orders')
        .update({'status': OrderStatus.billed.name})
        .eq('id', orderId);

    return get(billId);
  }

  Bill _mapBillRow(dynamic row) {
    final map = Map<String, dynamic>.from(row as Map);
    final customer = map.remove('customers');
    if (customer is Map) {
      map['customer_shop_name'] = customer['shop_name'];
    }
    final itemsRaw = map.remove('bill_items');
    final bill = Bill.fromJson(map);
    if (itemsRaw is List) {
      final items = itemsRaw
          .map((i) => BillItem.fromJson(Map<String, dynamic>.from(i as Map)))
          .toList();
      return bill.copyWith(items: items);
    }
    return bill;
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) throw Exception('Supabase not configured');
    return client;
  }
}
