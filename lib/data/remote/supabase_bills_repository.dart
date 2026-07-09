import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/report_range.dart';
import '../../domain/enums.dart';
import '../../domain/models/bill.dart';
import '../../domain/models/bill_item.dart';
import '../repositories/bills_repository.dart';
import '../repositories/payments_repository.dart';

class SupabaseBillsRepository implements BillsRepository {
  SupabaseBillsRepository(this._client, PaymentsRepository payments);

  final SupabaseClient? _client;

  @override
  Future<List<Bill>> list({int offset = 0, int? limit}) async {
    final client = _requireClient();
    var query = client
        .from('bills')
        .select('*, customers(shop_name)')
        .order('created_at', ascending: false);
    if (limit != null) {
      query = query.range(offset, offset + limit - 1);
    }
    final rows = await query;
    return (rows as List).map(_mapBillRow).toList();
  }

  @override
  Future<List<Bill>> search(String query, {int limit = 50}) async {
    final client = _requireClient();
    final rows = await client
        .from('bills')
        .select('*, customers(shop_name)')
        .ilike('bill_no', '%$query%')
        .order('created_at', ascending: false)
        .limit(limit);
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
    // Net of credit notes — same source as report_sales_daily.
    final client = _requireClient();
    final day = nptDateString(nptDayStartUtc());
    final rows = await client
        .from('report_sales_daily')
        .select('total_sales')
        .eq('sale_date', day);
    var total = 0;
    for (final row in rows as List) {
      total += ((row as Map)['total_sales'] as num?)?.toInt() ?? 0;
    }
    return total;
  }

  @override
  Future<int> todaysBillCount() async {
    final client = _requireClient();
    final start = nptDayStartUtc();
    final count = await client
        .from('bills')
        .count(CountOption.exact)
        .gte('created_at', start.toIso8601String());
    return count;
  }

  @override
  Future<int> yesterdaysSales() async {
    final client = _requireClient();
    final yesterdayStart =
        nptDayStartUtc().subtract(const Duration(days: 1));
    final day = nptDateString(yesterdayStart);
    final rows = await client
        .from('report_sales_daily')
        .select('total_sales')
        .eq('sale_date', day);
    var total = 0;
    for (final row in rows as List) {
      total += ((row as Map)['total_sales'] as num?)?.toInt() ?? 0;
    }
    return total;
  }

  @override
  Future<List<Bill>> listTodaysBills({int limit = 20}) async {
    final client = _requireClient();
    final start = nptDayStartUtc();
    final rows = await client
        .from('bills')
        .select('*, customers(shop_name)')
        .gte('created_at', start.toIso8601String())
        .order('created_at', ascending: false)
        .limit(limit);
    return (rows as List).map(_mapBillRow).toList();
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
  }) {
    return _createViaRpc(
      customerId: customerId,
      orderId: null,
      status: status,
      discount: discount,
      grandTotal: grandTotal,
      lines: lines,
      paymentMethod: paymentMethod,
      paymentRefNote: paymentRefNote,
      paymentAmount: paymentAmount,
    );
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
  }) {
    return _createViaRpc(
      customerId: customerId,
      orderId: orderId,
      status: status,
      discount: discount,
      grandTotal: grandTotal,
      lines: lines,
      paymentMethod: paymentMethod,
      paymentRefNote: paymentRefNote,
      paymentAmount: paymentAmount,
    );
  }

  /// Single transactional + idempotent server-side bill creation.
  Future<Bill> _createViaRpc({
    required String? customerId,
    required String? orderId,
    required BillStatus status,
    required int discount,
    required int grandTotal,
    required List<BillLineInput> lines,
    required PaymentMethod paymentMethod,
    required String? paymentRefNote,
    required int? paymentAmount,
  }) async {
    final client = _requireClient();
    final billId = const Uuid().v4();

    int? amount;
    if (customerId != null || orderId != null) {
      if (status == BillStatus.paid) {
        amount = grandTotal;
      } else if (status == BillStatus.partial) {
        amount = paymentAmount ?? 0;
      }
    }

    final payload = <String, dynamic>{
      'id': billId,
      'customer_id': customerId,
      'order_id': orderId,
      'discount': discount,
      'status': status.name,
      'items': lines
          .map(
            (line) => {
              'product_id': line.productId,
              'name_snapshot': line.nameSnapshot,
              'qty': line.qty,
              'rate': line.rate,
              'discount': line.discount,
            },
          )
          .toList(),
      if (amount != null && amount > 0)
        'payment': {
          'amount': amount,
          'method': paymentMethod.name,
          'ref_note': paymentRefNote,
        },
    };

    final result = await client.rpc('create_bill', params: {'p': payload});
    final billJson =
        Map<String, dynamic>.from((result as Map)['bill'] as Map);
    final bill = Bill.fromJson(billJson);
    // Re-fetch with joined customer + items for display.
    return get(bill.id);
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
