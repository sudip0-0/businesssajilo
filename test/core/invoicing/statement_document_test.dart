import 'dart:ui';

import 'package:businesssajilo/core/invoicing/statement_document.dart';
import 'package:businesssajilo/core/utils/ledger_balance.dart';
import 'package:businesssajilo/domain/models/business.dart';
import 'package:businesssajilo/domain/models/ledger_entry.dart';
import 'package:flutter_test/flutter_test.dart';

const _labels = StatementLabels(
  title: 'Statement',
  period: 'Period',
  customer: 'Customer',
  date: 'Date',
  description: 'Description',
  debit: 'Debit',
  credit: 'Credit',
  balance: 'Balance',
  openingBalance: 'Opening balance',
  closingBalance: 'Closing balance',
);

const _business = Business(id: 'b1', name: 'Test Biz');

LedgerEntry _entry({
  required DateTime at,
  required String type,
  int debit = 0,
  int credit = 0,
}) {
  return LedgerEntry(
    customerId: 'c1',
    businessId: 'b1',
    occurredAt: at,
    entryType: type,
    description: type,
    debitPaisa: debit,
    creditPaisa: credit,
  );
}

void main() {
  final entries = withRunningBalance([
    _entry(at: DateTime.utc(2026, 1, 1), type: 'opening_balance', debit: 10000),
    _entry(at: DateTime.utc(2026, 2, 1), type: 'bill', debit: 50000),
    _entry(at: DateTime.utc(2026, 3, 1), type: 'payment', credit: 20000),
    _entry(at: DateTime.utc(2026, 6, 1), type: 'bill', debit: 30000),
    _entry(at: DateTime.utc(2026, 6, 15), type: 'payment', credit: 10000),
  ]);

  StatementDocument buildDoc({DateTime? from, required DateTime to}) {
    return StatementDocument.fromLedger(
      business: _business,
      customerLabel: 'Cust Shop',
      entries: entries,
      from: from,
      to: to,
      locale: const Locale('en'),
      labels: _labels,
      describeEntry: (e) => e.description,
    );
  }

  group('StatementDocument.fromLedger', () {
    test('all-time statement starts at zero and closes at ledger balance', () {
      final doc = buildDoc(from: null, to: DateTime.utc(2026, 12, 31));
      expect(doc.openingBalance, 0);
      expect(doc.lines.length, 5);
      // 100 + 500 - 200 + 300 - 100 (in paisa).
      expect(doc.closingBalance, 60000);
      expect(doc.closingBalance, entries.last.runningBalance);
    });

    test('ranged statement carries exact opening balance', () {
      final doc = buildDoc(
        from: DateTime.utc(2026, 5, 1),
        to: DateTime.utc(2026, 12, 31),
      );
      // Everything before May: 100 + 500 - 200 = 400 paisa.
      expect(doc.openingBalance, 40000);
      expect(doc.lines.length, 2);
      expect(doc.closingBalance, 60000);
      // Invariant: opening + range movement == closing.
      final movement = doc.lines.fold<int>(
        0,
        (sum, l) => sum + l.debit - l.credit,
      );
      expect(doc.openingBalance + movement, doc.closingBalance);
    });

    test('entries after the end date are excluded', () {
      final doc = buildDoc(from: null, to: DateTime.utc(2026, 4, 1));
      expect(doc.lines.length, 3);
      expect(doc.closingBalance, 40000);
    });

    test('empty range closes at opening balance', () {
      final doc = buildDoc(
        from: DateTime.utc(2026, 7, 1),
        to: DateTime.utc(2026, 8, 1),
      );
      expect(doc.lines, isEmpty);
      expect(doc.openingBalance, 60000);
      expect(doc.closingBalance, 60000);
    });

    test('line balances equal the in-app running balance', () {
      final doc = buildDoc(from: null, to: DateTime.utc(2026, 12, 31));
      for (var i = 0; i < doc.lines.length; i++) {
        expect(doc.lines[i].balance, entries[i].runningBalance);
      }
    });

    test('uses Nepali business name for ne locale', () {
      final doc = StatementDocument.fromLedger(
        business: const Business(id: 'b1', name: 'Test Biz', nameNp: 'परीक्षण'),
        customerLabel: 'Cust',
        entries: entries,
        from: null,
        to: DateTime.utc(2026, 12, 31),
        locale: const Locale('ne'),
        labels: _labels,
        describeEntry: (e) => e.description,
      );
      expect(doc.businessDisplayName, 'परीक्षण');
    });
  });
}
