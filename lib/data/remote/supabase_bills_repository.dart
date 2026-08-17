import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/logging/sentry_scope.dart';
import '../../core/utils/report_range.dart';
import '../../domain/enums.dart';
import '../../domain/models/bill.dart';
import '../../domain/models/bill_item.dart';
import '../repositories/bills_repository.dart';
import '../repositories/payments_repository.dart';
import 'supabase_provider.dart';

const _billSelect =
    '*, customers(shop_name), members!bills_created_by_fkey(display_name, role)';
const _billSelectWithItems =
    '*, customers(shop_name), members!bills_created_by_fkey(display_name, role), bill_items(*)';

class SupabaseBillsRepository implements BillsRepository {
  SupabaseBillsRepository(this._client, PaymentsRepository payments);

  final SupabaseClient? _client;

  @override
  Future<List<Bill>> list({
    int offset = 0,
    int? limit,
    BillStatus? status,
  }) async {
    final client = requireSupabaseClient(_client);
    var query = client.from('bills').select(_billSelect);
    if (status != null) {
      query = query.eq('status', status.name);
    }
    var ordered = query.order('created_at', ascending: false);
    if (limit != null) {
      ordered = ordered.range(offset, offset + limit - 1);
    }
    final rows = await ordered;
    return (rows as List).map(_mapBillRow).toList();
  }

  @override
  Future<List<Bill>> listOpenForCustomer(String customerId) async {
    final client = requireSupabaseClient(_client);
    final rows = await client
        .from('bills')
        .select(_billSelect)
        .eq('customer_id', customerId)
        .inFilter('status', ['due', 'partial'])
        .order('created_at', ascending: true);
    return (rows as List).map(_mapBillRow).toList();
  }

  @override
  Future<List<Bill>> search(
    String query, {
    int limit = 50,
    int offset = 0,
    BillStatus? status,
  }) async {
    final client = requireSupabaseClient(_client);
    final q = query.trim();
    if (q.isEmpty && status == null) return list(limit: limit, offset: offset);

    final result = await client.rpc<dynamic>(
      'search_bills',
      params: {
        'p_query': q.isEmpty ? null : q,
        'p_status': status?.name,
        'p_from': null,
        'p_to': null,
        'p_offset': offset,
        'p_limit': limit,
      },
    );
    final rows = result is List ? result : const [];
    return rows.map(_mapBillRow).toList();
  }

  @override
  Future<List<Bill>> listInRange({
    required DateTime from,
    required DateTime to,
    String? query,
    int offset = 0,
    int? limit,
    BillStatus? status,
  }) async {
    final client = requireSupabaseClient(_client);
    final q = query?.trim();
    if ((q != null && q.isNotEmpty) || status != null) {
      final result = await client.rpc<dynamic>(
        'search_bills',
        params: {
          'p_query': (q == null || q.isEmpty) ? null : q,
          'p_status': status?.name,
          'p_from': from.toUtc().toIso8601String(),
          'p_to': to.toUtc().toIso8601String(),
          'p_offset': offset,
          'p_limit': limit ?? 50,
        },
      );
      final rows = result is List ? result : const [];
      return rows.map(_mapBillRow).toList();
    }

    final fromIso = from.toUtc().toIso8601String();
    final toIso = to.toUtc().toIso8601String();
    var request = client
        .from('bills')
        .select(_billSelect)
        .gte('created_at', fromIso)
        .lt('created_at', toIso)
        .order('created_at', ascending: false);
    if (limit != null) {
      request = request.range(offset, offset + limit - 1);
    }
    final rows = await request;
    return (rows as List).map(_mapBillRow).toList();
  }

  @override
  Future<Bill> get(String id) async {
    final client = requireSupabaseClient(_client);
    final row = await client
        .from('bills')
        .select(_billSelectWithItems)
        .eq('id', id)
        .single();
    return _mapBillRow(row);
  }

  @override
  Future<int> todaysSales() async {
    // Net of credit notes â€” same source as report_sales_daily.
    final client = requireSupabaseClient(_client);
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
    final client = requireSupabaseClient(_client);
    final start = nptDayStartUtc();
    final end = start.add(const Duration(days: 1));
    final count = await client
        .from('bills')
        .count(CountOption.exact)
        .gte('created_at', start.toIso8601String())
        .lt('created_at', end.toIso8601String());
    return count;
  }

  @override
  Future<int> yesterdaysSales() async {
    final client = requireSupabaseClient(_client);
    final yesterdayStart = nptDayStartUtc().subtract(const Duration(days: 1));
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
    final client = requireSupabaseClient(_client);
    final start = nptDayStartUtc();
    final end = start.add(const Duration(days: 1));
    final rows = await client
        .from('bills')
        .select(_billSelect)
        .gte('created_at', start.toIso8601String())
        .lt('created_at', end.toIso8601String())
        .order('created_at', ascending: false)
        .limit(limit);
    return (rows as List).map(_mapBillRow).toList();
  }

  @override
  Future<int> unsyncedTodaysSales() async => 0;

  @override
  Future<Bill> create({
    required String createdByMemberId,
    String? customerId,
    String? guestName,
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
      guestName: guestName,
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
    String? guestName,
    required String? orderId,
    required BillStatus status,
    required int discount,
    required int grandTotal,
    required List<BillLineInput> lines,
    required PaymentMethod paymentMethod,
    required String? paymentRefNote,
    required int? paymentAmount,
  }) async {
    final client = requireSupabaseClient(_client);
    final billId = const Uuid().v4();

    int? amount;
    if (customerId != null || orderId != null) {
      if (status == BillStatus.paid) {
        amount = grandTotal;
      } else if (status == BillStatus.partial) {
        amount = paymentAmount ?? 0;
      }
    }

    final trimmedGuest = guestName?.trim();
    final payload = <String, dynamic>{
      'id': billId,
      'customer_id': customerId,
      'order_id': orderId,
      'discount': discount,
      'status': status.name,
      if (customerId == null && trimmedGuest != null && trimmedGuest.isNotEmpty)
        'guest_name': trimmedGuest,
      'items': lines
          .map(
            (line) => {
              'product_id': line.productId.isEmpty ? null : line.productId,
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

    final result = await tracedOp(
      'rpc.create_bill',
      'db.rpc',
      () => client.rpc('create_bill', params: {'p': payload}),
    );
    final billJson = Map<String, dynamic>.from((result as Map)['bill'] as Map);
    final bill = Bill.fromJson(billJson);
    // Re-fetch with joined customer + items for display.
    return get(bill.id);
  }

  @override
  Future<Bill> recordAmountSale({
    required String customerId,
    required String createdByMemberId,
    required int amountPaisa,
    String? refNote,
    bool paidNow = false,
    PaymentMethod paymentMethod = PaymentMethod.cash,
  }) async {
    final client = requireSupabaseClient(_client);
    final billId = const Uuid().v4();
    final payload = <String, dynamic>{
      'id': billId,
      'customer_id': customerId,
      'amount': amountPaisa,
      'ref_note': refNote,
      if (paidNow)
        'payment': {
          'amount': amountPaisa,
          'method': paymentMethod.name,
          'ref_note': refNote,
        },
    };
    await client.rpc('record_customer_sale', params: {'p': payload});
    return get(billId);
  }

  Bill _mapBillRow(dynamic row) {
    final map = Map<String, dynamic>.from(row as Map);
    final customer = map.remove('customers');
    final member = map.remove('members');
    final joinedShop = customer is Map
        ? (customer['shop_name'] as String?)?.trim()
        : null;
    final guestName = (map.remove('guest_name') as String?)?.trim();
    final displayName = (joinedShop != null && joinedShop.isNotEmpty)
        ? joinedShop
        : (guestName != null && guestName.isNotEmpty ? guestName : null);
    if (displayName != null) {
      map['customer_shop_name'] = displayName;
    }
    if (member is Map) {
      final name = (member['display_name'] as String?)?.trim();
      if (name != null && name.isNotEmpty) {
        map['created_by_name'] = name;
      }
      final role = member['role']?.toString();
      if (role != null && role.isNotEmpty) {
        map['created_by_role'] = role;
      }
    }
    final itemsRaw = map.remove('bill_items');
    final bill = Bill.fromJson(map);
    if (itemsRaw is List) {
      final items = itemsRaw.map((i) {
        final itemMap = Map<String, dynamic>.from(i as Map);
        itemMap['product_id'] ??= '';
        return BillItem.fromJson(itemMap);
      }).toList();
      return bill.copyWith(items: items);
    }
    return bill;
  }
}
