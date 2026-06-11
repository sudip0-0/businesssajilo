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
        formatNpr(Paisa.fromRupees(123456), showSymbol: false, showPaisa: false),
        '1,23,456',
      );
    });
  });

  group('parseNpr', () {
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
