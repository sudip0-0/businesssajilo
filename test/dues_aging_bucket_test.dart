import 'package:businesssajilo/core/utils/report_range.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bucketFromAgeDays assigns 0_30 for 30 days or less', () {
    expect(bucketFromAgeDays(0), '0_30');
    expect(bucketFromAgeDays(30), '0_30');
  });

  test('bucketFromAgeDays assigns 31_60 for 31 to 60 days', () {
    expect(bucketFromAgeDays(31), '31_60');
    expect(bucketFromAgeDays(60), '31_60');
  });

  test('bucketFromAgeDays assigns 60_plus beyond 60 days', () {
    expect(bucketFromAgeDays(61), '60_plus');
    expect(bucketFromAgeDays(365), '60_plus');
  });
}
