import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/bill_search_match.dart';
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
  Future<List<Bill>> list({int offset = 0, int? limit}) async {
    final client = requireSupabaseClient(_client);
    var query = client
        .from('bills')
        .select(_billSelect)
        .order('created_at', ascending: false);
    if (limit != null) {
      query = query.range(offset, offset + limit - 1);
    }
    final rows = await query;
    return (rows as List).map(_mapBillRow).toList();
  }

  @override
  Future<List<Bill>> search(String query, {int limit = 50}) async {
    final client = requireSupabaseClient(_client);
    final q = query.trim();
    if (q.isEmpty) return list(limit: limit);

    final amountPaisa = billSearchAmountPaisa(q);
    final customers = await client
        .from('customers')
        .select('id')
        .ilike('shop_name', '%$q%')
        .limit(100);
    final customerIds = (customers as List)
        .map((r) => (r as Map)['id'] as String)
        .toList();

    final orParts = <String>['bill_no.ilike.%$q%', 'guest_name.ilike.%$q%'];
    if (customerIds.isNotEmpty) {
      orParts.add('customer_id.in.(${customerIds.join(',')})');
    }
    if (amountPaisa != null) {
      orParts.add('grand_total.eq.$amountPaisa');
    }

    const candidateLimit = 100;
    final filteredRows = await client
        .from('bills')
        .select(_billSelect)
        .or(orParts.join(','))
        .order('created_at', ascending: false)
        .limit(candidateLimit);
    // Recent window so free-text dates can still match.
    final recentRows = await client
        .from('bills')
        .select(_billSelect)
        .order('created_at', ascending: false)
        .limit(candidateLimit);

    final byId = <String, Bill>{};
    for (final row in [...filteredRows as List, ...recentRows as List]) {
      final bill = _mapBillRow(row);
      byId.putIfAbsent(bill.id, () => bill);
    }
    final matched = byId.values
        .where((bill) => billMatchesSearch(bill, query: q))
        .toList();
    matched.sort((a, b) {
      final aAt = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bAt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bAt.compareTo(aAt);
    });
    if (matched.length <= limit) return matched;
    return matched.sublist(0, limit);
  }

  @override
  Future<List<Bill>> listInRange({
    required DateTime from,
    required DateTime to,
    String? query,
    int offset = 0,
    int? limit,
  }) async {
    final client = requireSupabaseClient(_client);
    final fromIso = from.toUtc().toIso8601String();
    final toIso = to.toUtc().toIso8601String();
    final q = query?.trim();

    if (q == null || q.isEmpty) {
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

    final customers = await client
        .from('customers')
        .select('id')
        .ilike('shop_name', '%$q%')
        .limit(100);
    final customerIds = (customers as List)
        .map((r) => (r as Map)['id'] as String)
        .toList();

    final orParts = <String>['bill_no.ilike.%$q%', 'guest_name.ilike.%$q%'];
    if (customerIds.isNotEmpty) {
      orParts.add('customer_id.in.(${customerIds.join(',')})');
    }

    var request = client
        .from('bills')
        .select(_billSelect)
        .gte('created_at', fromIso)
        .lt('created_at', toIso)
        .or(orParts.join(','))
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
    final count = await client
        .from('bills')
        .count(CountOption.exact)
        .gte('created_at', start.toIso8601String());
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
    final rows = await client
        .from('bills')
        .select(_billSelect)
        .gte('created_at', start.toIso8601String())
        .order('created_at', ascending: false)
        .limit(limit);
    return (rows as List).map(_mapBillRow).toList();
  }

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
      if (customerId == null &&
          trimmedGuest != null &&
          trimmedGuest.isNotEmpty)
        'guest_name': trimmedGuest,
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

