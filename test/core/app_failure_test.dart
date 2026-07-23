import 'dart:async';

import 'package:businesssajilo/core/errors/app_failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('AppFailure.from', () {
    test('maps Postgrest 42501 to permission', () {
      final failure = AppFailure.from(
        const PostgrestException(message: 'forbidden', code: '42501'),
      );
      expect(failure, isA<AppFailurePermission>());
    });

    test('maps Postgrest 23505 to conflict', () {
      final failure = AppFailure.from(
        const PostgrestException(message: 'duplicate', code: '23505'),
      );
      expect(failure, isA<AppFailureConflict>());
    });

    test('maps validation-looking Postgrest messages', () {
      final failure = AppFailure.from(
        const PostgrestException(message: 'amount must be positive'),
      );
      expect(failure, isA<AppFailureValidation>());
      expect(failure.detail, 'amount must be positive');
    });

    test('maps AuthException to permission', () {
      final failure = AppFailure.from(const AuthException('bad creds'));
      expect(failure, isA<AppFailurePermission>());
    });

    test('maps TimeoutException to network', () {
      final failure = AppFailure.from(
        TimeoutException('timed out', const Duration(seconds: 5)),
      );
      expect(failure, isA<AppFailureNetwork>());
    });

    test('maps SocketException-like strings to network', () {
      final failure = AppFailure.from(
        Exception('SocketException: Failed host lookup'),
      );
      expect(failure, isA<AppFailureNetwork>());
    });

    test('passes through existing AppFailure', () {
      const original = AppFailure.notConfigured();
      expect(AppFailure.from(original), same(original));
    });

    test('unknown for arbitrary exceptions', () {
      final failure = AppFailure.from(StateError('boom'));
      expect(failure, isA<AppFailureUnknown>());
    });
  });
}
