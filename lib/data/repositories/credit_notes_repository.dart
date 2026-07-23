import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/credit_note.dart';
import '../remote/supabase_credit_notes_repository.dart';
import '../remote/supabase_provider.dart';

final creditNotesRepositoryProvider = Provider<CreditNotesRepository>((ref) {
  return SupabaseCreditNotesRepository(ref.watch(supabaseClientProvider));
});

abstract class CreditNotesRepository {
  Future<Map<String, int>> returnedQtyByBillItem(String billId);
  Future<CreditNote> create({
    required String billId,
    required String createdByMemberId,
    required List<CreditNoteLineInput> lines,
    required bool restock,
    String? reason,
  });
}
