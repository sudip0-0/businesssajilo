import 'dart:convert';

import 'package:businesssajilo/core/export/csv_writer.dart';
import 'package:businesssajilo/core/export/report_csv_export.dart';
import 'package:businesssajilo/domain/models/ledger_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const writer = CsvWriter();

  test('financial CSV retains fractional totals', () {
    expect(fiscalSummaryCsvRows([('Month', 1, 10029)]).last.last, 'रू 100.29');
  });

  test('ledger CSV retains debit credit and signed balance paisa', () {
    final rows = ledgerCsvRows([
      LedgerEntry(
        customerId: 'c1',
        businessId: 'b1',
        occurredAt: DateTime(2026),
        entryType: 'payment',
        description: 'Payment',
        debitPaisa: 10029,
        creditPaisa: 10030,
        runningBalance: -1,
      ),
    ]);
    expect(rows.last.sublist(3), ['रू 100.29', 'रू 100.30', '-रू 0.01']);
  });

  test('build prepends UTF-8 BOM', () {
    final csv = writer.build([
      ['A', 'B'],
    ]);
    expect(csv.startsWith('\uFEFF'), isTrue);
    expect(csv.contains('A,B'), isTrue);
  });

  test('escapes commas quotes and newlines', () {
    final csv = writer.build([
      ['plain', 'has,comma', 'has"quote', 'line\nbreak'],
    ]);
    expect(csv, contains('"has,comma"'));
    expect(csv, contains('"has""quote"'));
    expect(csv, contains('"line\nbreak"'));
  });

  test('encodeUtf8 preserves Nepali characters', () {
    final csv = writer.build([
      ['नाम', 'रू १,२३४'],
    ]);
    final bytes = writer.encodeUtf8(csv);
    expect(utf8.decode(bytes), contains('नाम'));
  });
}
