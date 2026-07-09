import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/credit_notes_repository.dart';
import '../../domain/models/bill.dart';
import '../../domain/models/credit_note.dart';
import '../auth/providers/auth_provider.dart';
import 'credit_note_draft.dart';
import 'invalidate_billing.dart';

Future<CreditNote> saveCreditNote(
  Ref ref, {
  required Bill bill,
  required List<CreditNoteLineDraft> selected,
  required bool restock,
  String? reason,
}) async {
  final memberId = ref.read(authProvider).value?.member?.id;
  if (memberId == null) {
    throw StateError('Not authenticated');
  }
  final note = await ref
      .read(creditNotesRepositoryProvider)
      .create(
        billId: bill.id,
        createdByMemberId: memberId,
        restock: restock,
        reason: reason,
        lines: selected.map((line) => line.toInput()).toList(),
      );
  invalidateAfterCreditNoteSaved(
    ref,
    billId: bill.id,
    customerId: bill.customerId,
  );
  return note;
}
