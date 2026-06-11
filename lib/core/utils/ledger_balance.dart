import '../../domain/models/ledger_entry.dart';

/// Computes running balance for ledger statement rows.
/// Positive balance = customer owes the business.
List<LedgerEntry> withRunningBalance(List<LedgerEntry> entries) {
  final sorted = [...entries]
    ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
  var balance = 0;
  return sorted.map((e) {
    balance += e.debitPaisa - e.creditPaisa;
    return e.copyWith(runningBalance: balance);
  }).toList();
}
