import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../domain/enums.dart';
import '../../domain/models/payment.dart';
import '../repositories/payments_repository.dart';

class SupabasePaymentsRepository implements PaymentsRepository {
  SupabasePaymentsRepository(this._client);

  final SupabaseClient? _client;

  @override
  Future<List<Payment>> listByCustomer(String customerId) async {
    final client = _requireClient();
    final rows = await client
        .from('payments')
        .select()
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);
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
    required String receivedByMemberId,
    bool enqueueRemote = true,
  }) async {
    final client = _requireClient();
    final row = await client
        .from('payments')
        .insert({
          'id': id ?? const Uuid().v4(),
          'customer_id': customerId,
          'bill_id': ?billId,
          'amount': amount,
          'method': method.name,
          'ref_note': ?refNote,
          'received_by': receivedByMemberId,
        })
        .select()
        .single();
    return Payment.fromJson(row);
  }

  @override
  Future<int> totalDues() async {
    final client = _requireClient();
    final rows = await client.from('customer_balances').select('balance_due');
    var total = 0;
    for (final row in rows as List) {
      final due = (row as Map)['balance_due'] as num?;
      if (due != null && due > 0) total += due.toInt();
    }
    return total;
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) throw Exception('Supabase not configured');
    return client;
  }
}
