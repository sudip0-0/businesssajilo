import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/pagination.dart';
import '../../domain/enums.dart';
import '../../domain/models/payment.dart';
import '../repositories/payments_repository.dart';
import 'supabase_provider.dart';

class SupabasePaymentsRepository implements PaymentsRepository {
  SupabasePaymentsRepository(this._client);

  final SupabaseClient? _client;

  @override
  Future<List<Payment>> listByCustomer(
    String customerId, {
    int offset = 0,
    int limit = kListPageSize,
  }) async {
    final client = requireSupabaseClient(_client);
    final rows = await client
        .from('payments')
        .select()
        .eq('customer_id', customerId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return (rows as List)
        .map((row) => Payment.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Payment> record({
    String? id,
    required String customerId,
    required int amount,
    required PaymentMethod method,
    String? refNote,
    String? billId,
    String? allocate,
    required String receivedByMemberId,
    bool enqueueRemote = true,
  }) async {
    final client = requireSupabaseClient(_client);
    final paymentId = id ?? const Uuid().v4();
    final result = await client.rpc<dynamic>(
      'record_payment',
      params: {
        'p': {
          'id': paymentId,
          'customer_id': customerId,
          'bill_id': ?billId,
          'amount': amount,
          'method': method.name,
          'ref_note': ?refNote,
          'allocate': ?allocate,
          'received_by': receivedByMemberId,
        },
      },
    );
    final map = Map<String, dynamic>.from(result as Map);
    final payment = Map<String, dynamic>.from(map['payment'] as Map);
    return Payment.fromJson(payment);
  }

  @override
  Future<int> totalDues() async {
    final client = requireSupabaseClient(_client);
    final result = await client.rpc<dynamic>('total_dues');
    return (result as num?)?.toInt() ?? 0;
  }

  @override
  Future<int> totalReceivedForBill(String billId) async {
    final client = requireSupabaseClient(_client);
    final rows = await client
        .from('payments')
        .select('amount')
        .eq('bill_id', billId);
    return (rows as List).fold<int>(0, (sum, row) {
      final amount = (row as Map)['amount'];
      return sum + ((amount as num?)?.toInt() ?? 0);
    });
  }
}
