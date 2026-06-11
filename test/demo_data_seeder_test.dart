import 'package:businesssajilo/features/onboarding/demo_data_seeder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DemoSeedResult has loaded and skipped values', () {
    expect(DemoSeedResult.values.length, 2);
    expect(DemoSeedResult.loaded.name, 'loaded');
    expect(DemoSeedResult.skipped.name, 'skipped');
  });
}
