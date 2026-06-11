import 'package:businesssajilo/core/utils/bs_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final utc = DateTime.utc(2026, 7, 12, 10, 0);

  test('ad formats English date', () {
    expect(BsDate.ad(utc), '12 Jul 2026');
  });

  test('both combines BS and AD', () {
    final both = BsDate.both(utc);
    expect(both, contains('12 Jul 2026'));
    expect(both, contains('·'));
  });

  test('bs returns non-empty Nepali date string', () {
    expect(BsDate.bs(utc).isNotEmpty, isTrue);
  });
}
