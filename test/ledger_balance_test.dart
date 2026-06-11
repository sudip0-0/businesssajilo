import 'package:businesssajilo/core/utils/ledger_balance.dart';
import 'package:businesssajilo/domain/models/ledger_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('withRunningBalance computes cumulative balance', () {
    final entries = [
      LedgerEntry(
        customerId: 'c1',
        businessId: 'b1',
        occurredAt: DateTime(2026, 1, 1),
        entryType: 'opening_balance',
        description: 'Opening',
        debitPaisa: 10000,
      ),
      LedgerEntry(
        customerId: 'c1',
        businessId: 'b1',
        occurredAt: DateTime(2026, 1, 2),
        entryType: 'payment',
        description: 'Cash',
        creditPaisa: 2500,
      ),
      LedgerEntry(
        customerId: 'c1',
        businessId: 'b1',
        occurredAt: DateTime(2026, 1, 3),
        entryType: 'payment',
        description: 'Wallet',
        creditPaisa: 1500,
      ),
    ];

    final result = withRunningBalance(entries);
    expect(result[0].runningBalance, 10000);
    expect(result[1].runningBalance, 7500);
    expect(result[2].runningBalance, 6000);
  });
}
