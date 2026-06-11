import '../../domain/models/ledger_entry.dart';

int _entryTypeRank(String type) => switch (type) {
      'opening_balance' => 0,
      'bill' => 1,
      'payment' => 2,
      _ => 3,
    };

/// Stable comparison: occurred_at, then entry type
/// (opening_balance < bill < payment), then ref_id.
int compareLedgerEntries(LedgerEntry a, LedgerEntry b) {
  final byTime = a.occurredAt.compareTo(b.occurredAt);
  if (byTime != 0) return byTime;
  final byType = _entryTypeRank(a.entryType).compareTo(_entryTypeRank(b.entryType));
  if (byType != 0) return byType;
  return (a.refId ?? '').compareTo(b.refId ?? '');
}

/// Computes running balance for ledger statement rows.
/// Positive balance = customer owes the business.
List<LedgerEntry> withRunningBalance(List<LedgerEntry> entries) {
  final sorted = [...entries]..sort(compareLedgerEntries);
  var balance = 0;
  return sorted.map((e) {
    balance += e.debitPaisa - e.creditPaisa;
    return e.copyWith(runningBalance: balance);
  }).toList();
}
