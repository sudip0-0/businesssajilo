import 'dart:convert';

import 'package:businesssajilo/core/export/csv_writer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const writer = CsvWriter();

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
