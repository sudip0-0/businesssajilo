import 'package:businesssajilo/core/config/env.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Firebase is not configured without dart-defines', () {
    expect(Env.isFirebaseConfigured, isFalse);
  });
}
