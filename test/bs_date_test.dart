import 'package:businesssajilo/core/utils/bs_date.dart';
import 'package:flutter/material.dart';
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

  test('time formats local clock time', () {
    final formatted = BsDate.time(utc);
    expect(formatted, isNotEmpty);
    expect(formatted, isNot(contains('Jul')));
    expect(formatted, contains(':'));
  });

  test('time uses Nepali digits for ne locale', () {
    final formatted = BsDate.time(utc, locale: const Locale('ne'));
    expect(formatted, isNotEmpty);
    expect(formatted, contains(':'));
    expect(formatted, isNot(contains(RegExp(r'[0-9]'))));
  });

  test('bothWithTime appends local time', () {
    final withTime = BsDate.bothWithTime(utc);
    expect(withTime, startsWith(BsDate.both(utc)));
    expect(withTime, contains(BsDate.time(utc)));
  });

  test('bs returns non-empty Nepali date string', () {
    expect(BsDate.bs(utc).isNotEmpty, isTrue);
  });
}
