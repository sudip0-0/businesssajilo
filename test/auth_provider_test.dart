import 'package:businesssajilo/data/repositories/auth_repository.dart';
import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/domain/models/auth_user.dart';
import 'package:businesssajilo/domain/models/member.dart';
import 'package:businesssajilo/domain/models/session_state.dart';
import 'package:businesssajilo/features/auth/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

const _session = SessionState(
  user: AuthUser(id: 'u1', email: 'owner@test.com'),
  member: Member(
    id: 'm1',
    businessId: 'b1',
    authUserId: 'u1',
    role: Role.owner,
    displayName: 'Owner',
  ),
);

Future<void> _waitForAuth(ProviderContainer container) async {
  for (var i = 0; i < 20; i++) {
    if (!container.read(authProvider).isLoading) return;
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late _MockAuthRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = _MockAuthRepository();
    when(() => repo.authStateChanges).thenAnswer((_) => const Stream.empty());
    when(() => repo.loadSession()).thenAnswer((_) async => _session);
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
  });

  tearDown(() => container.dispose());

  test('deleteAccount clears session after repository succeeds', () async {
    when(
      () => repo.deleteAccount(deleteBusiness: false, password: 'secret'),
    ).thenAnswer((_) async {});

    await _waitForAuth(container);
    await container
        .read(authProvider.notifier)
        .deleteAccount(password: 'secret');

    expect(container.read(authProvider).value, SessionState.empty);
    verify(
      () => repo.deleteAccount(deleteBusiness: false, password: 'secret'),
    ).called(1);
  });

  test('updateOwnPassword reloads session after password change', () async {
    when(
      () => repo.updateOwnPassword('newpass123', currentPassword: 'oldpass'),
    ).thenAnswer((_) async {});
    when(() => repo.loadSession()).thenAnswer((_) async {
      return SessionState(
        user: _session.user,
        member: _session.member!.copyWith(mustChangePassword: false),
      );
    });

    await _waitForAuth(container);
    await container.read(authProvider.notifier).updateOwnPassword(
          'newpass123',
          currentPassword: 'oldpass',
        );

    expect(container.read(authProvider).value?.mustChangePassword, isFalse);
  });

  test('signIn surfaces AccountDeactivatedException', () async {
    when(
      () => repo.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async {});
    when(() => repo.loadSession()).thenThrow(const AccountDeactivatedException());

    await _waitForAuth(container);
    final controller = container.read(authProvider.notifier);

    expect(
      () => controller.signIn('staff@test.com', 'password123'),
      throwsA(isA<AccountDeactivatedException>()),
    );
  });
}
