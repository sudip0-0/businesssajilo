import 'package:businesssajilo/data/repositories/auth_repository.dart';
import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/domain/models/member.dart';
import 'package:businesssajilo/domain/models/session_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('AccountDeactivatedException', () {
    test('is distinct from generic exceptions', () {
      const e = AccountDeactivatedException();
      expect(e.toString(), contains('deactivated'));
    });
  });

  group('SessionState', () {
    test('mustChangePassword reflects member flag', () {
      const forced = SessionState(
        member: Member(
          id: 'm1',
          businessId: 'b1',
          authUserId: 'u1',
          role: Role.sales,
          displayName: 'Staff',
          mustChangePassword: true,
        ),
      );
      expect(forced.mustChangePassword, isTrue);
      expect(SessionState.empty.mustChangePassword, isFalse);
    });

    test('isAuthenticated requires active member', () {
      const inactive = SessionState(
        member: Member(
          id: 'm1',
          businessId: 'b1',
          authUserId: 'u1',
          role: Role.sales,
          displayName: 'Staff',
          isActive: false,
        ),
      );
      expect(inactive.isAuthenticated, isFalse);
    });
  });

  group('AuthRepository', () {
    test('loadSession returns empty when client is null', () async {
      final repo = AuthRepository(null);
      expect(await repo.loadSession(), SessionState.empty);
    });

    test('deleteAccount requires password for self deletion', () async {
      final repo = AuthRepository(SupabaseClient('http://localhost', 'anon-key'));
      expect(
        () => repo.deleteAccount(password: null),
        throwsA(isA<AuthException>()),
      );
      expect(
        () => repo.deleteAccount(password: ''),
        throwsA(isA<AuthException>()),
      );
    });

    test('deleteAccount requires password for business deletion', () async {
      final repo = AuthRepository(SupabaseClient('http://localhost', 'anon-key'));
      expect(
        () => repo.deleteAccount(deleteBusiness: true, password: ''),
        throwsA(isA<AuthException>()),
      );
    });

    test('signIn throws when Supabase is not configured', () async {
      final repo = AuthRepository(null);
      expect(
        () => repo.signIn(email: 'a@b.com', password: 'password123'),
        throwsA(isA<AuthException>()),
      );
    });
  });
}
