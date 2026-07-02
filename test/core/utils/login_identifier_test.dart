import 'package:businesssajilo/core/utils/login_identifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeNepalPhone', () {
    test('accepts plain 10-digit mobile', () {
      expect(normalizeNepalPhone('9841000000'), '+9779841000000');
    });

    test('accepts +977 prefix', () {
      expect(normalizeNepalPhone('+9779841000000'), '+9779841000000');
    });

    test('accepts 977 prefix without plus', () {
      expect(normalizeNepalPhone('9779841000000'), '+9779841000000');
    });

    test('accepts leading zero', () {
      expect(normalizeNepalPhone('09841000000'), '+9779841000000');
    });

    test('strips spaces, dashes, parentheses', () {
      expect(normalizeNepalPhone('+977 984-100 (0000)'), '+9779841000000');
    });

    test('rejects landlines and short numbers', () {
      expect(normalizeNepalPhone('015550123'), null);
      expect(normalizeNepalPhone('98410'), null);
      expect(normalizeNepalPhone(''), null);
      expect(normalizeNepalPhone('abc'), null);
    });

    test('rejects numbers not starting with 9', () {
      expect(normalizeNepalPhone('8841000000'), null);
    });
  });

  group('phoneLoginEmail', () {
    test('derives synthetic email from normalized phone', () {
      expect(
        phoneLoginEmail('+9779841000000'),
        '9841000000@phone.businesssajilo.app',
      );
    });
  });

  group('loginEmailForIdentifier', () {
    test('passes emails through trimmed', () {
      expect(
        loginEmailForIdentifier('  owner@test.com '),
        'owner@test.com',
      );
    });

    test('maps phone to synthetic email', () {
      expect(
        loginEmailForIdentifier('98 4100 0000'),
        '9841000000@phone.businesssajilo.app',
      );
    });

    test('returns unrecognized input trimmed (auth rejects it)', () {
      expect(loginEmailForIdentifier(' nonsense '), 'nonsense');
    });
  });

  group('isValidLoginIdentifier', () {
    test('valid email and phone', () {
      expect(isValidLoginIdentifier('a@b.com'), true);
      expect(isValidLoginIdentifier('9841000000'), true);
      expect(isValidLoginIdentifier('+977 9841000000'), true);
    });

    test('invalid input', () {
      expect(isValidLoginIdentifier(''), false);
      expect(isValidLoginIdentifier('not-an-email'), false);
      expect(isValidLoginIdentifier('a@'), false);
      expect(isValidLoginIdentifier('12345'), false);
    });
  });
}
