import 'package:businesssajilo/core/utils/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatNpr', () {
    test('formats with Nepali grouping', () {
      expect(formatNpr(Paisa.fromRupees(123456.50)), 'रू 1,23,456.50');
      expect(formatNpr(Paisa.fromRupees(1234567)), 'रू 12,34,567.00');
      expect(formatNpr(const Paisa(0)), 'रू 0.00');
      expect(formatNpr(Paisa.fromRupees(999)), 'रू 999.00');
      expect(formatNpr(Paisa.fromRupees(1000)), 'रू 1,000.00');
    });

    test('negative amounts', () {
      expect(formatNpr(Paisa.fromRupees(-2500.75)), '-रू 2,500.75');
    });

    test('without paisa or symbol', () {
      expect(
        formatNpr(
          Paisa.fromRupees(123456),
          showSymbol: false,
          showPaisa: false,
        ),
        '1,23,456',
      );
    });
  });

  group('parseNpr', () {
    test('exact decimal arithmetic and portable integer boundary', () {
      expect(parseNpr('90071992547409.91')?.value, 9007199254740991);
      expect(parseNpr('-90071992547409.91')?.value, -9007199254740991);
      expect(parseNpr('90071992547409.92'), isNull);
      expect(parseNpr('-90071992547409.92'), isNull);
      expect(parseNpr('0.29')?.value, 29);
      expect(parseNpr('1.01')?.value, 101);
    });

    test('localized and grouped amounts round trip', () {
      expect(parseNpr('रू १,२३,४५६.७८')?.value, 12345678);
      expect(parseNpr('NPR 123,456.78')?.value, 12345678);
      expect(parseNpr('-रू 0.01')?.value, -1);
      for (final value in [0, 1, -1, 12345678, 9007199254740991]) {
        expect(parseNpr(formatNpr(Paisa(value)))?.value, value);
      }
    });

    test('rejects unsafe or malformed input without throwing', () {
      for (final input in [
        'NaN',
        'Infinity',
        '-Infinity',
        '1e2',
        '1E-2',
        '1.001',
        '1.999',
        '1,2',
        '12,34',
        '1,,000',
        '1 000',
        '1.2.3',
        'रू रू 1',
        '1रू2',
        '--1',
        '.',
        '1.',
        '999999999999999999999999',
      ]) {
        expect(parseNpr(input), isNull, reason: input);
      }
    });
    test('parses formatted input', () {
      expect(parseNpr('1,23,456.50'), Paisa.fromRupees(123456.50));
      expect(parseNpr('रू 500'), Paisa.fromRupees(500));
      expect(parseNpr('abc'), isNull);
      expect(parseNpr(''), isNull);
    });
  });

  group('Paisa arithmetic', () {
    test('add and subtract stay exact', () {
      final a = Paisa.fromRupees(0.1);
      final b = Paisa.fromRupees(0.2);
      expect((a + b).value, 30);
      expect((b - a).value, 10);
    });
  });
}
