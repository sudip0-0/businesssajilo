import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/credit_note.dart';
import '../remote/supabase_provider.dart';

final creditNotesRepositoryProvider = Provider<CreditNotesRepository>((ref) {
  return CreditNotesRepository(ref.watch(supabaseClientProvider));
});

class CreditNotesRepository {
  CreditNotesRepository(this._client);

  final SupabaseClient? _client;

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase is not configured');
    }
    return client;
  }

  Future<Map<String, int>> returnedQtyByBillItem(String billId) async {
    final client = _requireClient();
    final rows = await client.rpc('bill_returned_qty', params: {'p_bill_id': billId});
    final map = <String, int>{};
    for (final row in rows as List) {
      final item = BillItemReturnSummary.fromJson(
        Map<String, dynamic>.from(row as Map),
      );
      map[item.billItemId] = item.returnedQty;
    }
    return map;
  }

  Future<CreditNote> create({
    required String billId,
    required String createdByMemberId,
    required List<CreditNoteLineInput> lines,
    required bool restock,
    String? reason,
  }) async {
    final client = _requireClient();
    final id = const Uuid().v4();
    final payload = {
      'id': id,
      'bill_id': billId,
      'restock': restock,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
      'items': lines
          .map(
            (line) => {
              'bill_item_id': line.billItemId,
              'qty_returned': line.qtyReturned,
              'rate': line.rate,
              'discount': line.discount,
            },
          )
          .toList(),
    };

    final result = await client.rpc('create_credit_note', params: {'p': payload});
    final map = Map<String, dynamic>.from(result as Map);
    final noteJson = Map<String, dynamic>.from(map['credit_note'] as Map);
    final note = CreditNote.fromJson(noteJson);

    final items = await client
        .from('credit_note_items')
        .select()
        .eq('credit_note_id', note.id);
    final parsedItems = (items as List)
        .map((row) => CreditNoteItem.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
    return note.copyWithItems(parsedItems);
  }
}
