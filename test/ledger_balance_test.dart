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

  test(
    'same-instant entries order opening_balance < bill < credit_note < payment',
    () {
      final at = DateTime(2026, 1, 1);
      final entries = [
        LedgerEntry(
          customerId: 'c1',
          businessId: 'b1',
          occurredAt: at,
          entryType: 'payment',
          description: 'Cash',
          creditPaisa: 500,
          refId: 'p1',
        ),
        LedgerEntry(
          customerId: 'c1',
          businessId: 'b1',
          occurredAt: at,
          entryType: 'credit_note',
          description: 'CN-0001',
          creditPaisa: 1000,
          refId: 'cn1',
        ),
        LedgerEntry(
          customerId: 'c1',
          businessId: 'b1',
          occurredAt: at,
          entryType: 'bill',
          description: 'Bill',
          debitPaisa: 2000,
          refId: 'b1',
        ),
        LedgerEntry(
          customerId: 'c1',
          businessId: 'b1',
          occurredAt: at,
          entryType: 'opening_balance',
          description: 'Opening',
          debitPaisa: 1000,
        ),
      ];

      final result = withRunningBalance(entries);
      expect(result.map((e) => e.entryType).toList(), [
        'opening_balance',
        'bill',
        'credit_note',
        'payment',
      ]);
      expect(result.last.runningBalance, 1500);
    },
  );

  test('same-instant entries order opening_balance < bill < payment', () {
    final at = DateTime(2026, 1, 1);
    final entries = [
      LedgerEntry(
        customerId: 'c1',
        businessId: 'b1',
        occurredAt: at,
        entryType: 'payment',
        description: 'Cash',
        creditPaisa: 500,
        refId: 'p1',
      ),
      LedgerEntry(
        customerId: 'c1',
        businessId: 'b1',
        occurredAt: at,
        entryType: 'bill',
        description: 'Bill',
        debitPaisa: 2000,
        refId: 'b1',
      ),
      LedgerEntry(
        customerId: 'c1',
        businessId: 'b1',
        occurredAt: at,
        entryType: 'opening_balance',
        description: 'Opening',
        debitPaisa: 1000,
      ),
    ];

    final result = withRunningBalance(entries);
    expect(result.map((e) => e.entryType).toList(), [
      'opening_balance',
      'bill',
      'payment',
    ]);
    expect(result.last.runningBalance, 2500);
  });

  test('same-instant same-type entries tie-break by refId', () {
    final at = DateTime(2026, 1, 1);
    final entries = [
      LedgerEntry(
        customerId: 'c1',
        businessId: 'b1',
        occurredAt: at,
        entryType: 'payment',
        description: 'B',
        creditPaisa: 100,
        refId: 'b',
      ),
      LedgerEntry(
        customerId: 'c1',
        businessId: 'b1',
        occurredAt: at,
        entryType: 'payment',
        description: 'A',
        creditPaisa: 200,
        refId: 'a',
      ),
    ];

    final result = withRunningBalance(entries);
    expect(result.map((e) => e.refId).toList(), ['a', 'b']);
  });
}
