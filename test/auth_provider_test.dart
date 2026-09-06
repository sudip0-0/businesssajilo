import 'dart:async';

import 'package:businesssajilo/core/notifications/push_service.dart';
import 'package:businesssajilo/core/notifications/push_service_provider.dart';

import 'package:businesssajilo/data/repositories/auth_repository.dart';
import 'package:businesssajilo/data/local/app_database.dart';
import 'package:businesssajilo/data/sync/sync_bundle_registry.dart';
import 'package:businesssajilo/data/sync/sync_providers.dart';
import 'package:businesssajilo/data/sync/sync_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/native.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;
import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/domain/models/auth_user.dart';
import 'package:businesssajilo/domain/models/member.dart';
import 'package:businesssajilo/domain/models/session_state.dart';
import 'package:businesssajilo/features/auth/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockPushService extends Mock implements PushService {}

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
  late _MockPushService push;
  late ProviderContainer container;

  setUp(() {
    repo = _MockAuthRepository();
    push = _MockPushService();
    when(push.unregister).thenAnswer((_) async {});
    when(() => push.registerForMember(any())).thenAnswer((_) async {});
    when(() => repo.authStateChanges).thenAnswer((_) => const Stream.empty());
    when(() => repo.loadSession()).thenAnswer((_) async => _session);
    when(() => repo.peekCachedSession()).thenAnswer((_) async => null);
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        pushServiceProvider.overrideWithValue(push),
      ],
    );
  });

  tearDown(() => container.dispose());

  for (final deleting in [false, true]) {
    test(
      'failed ${deleting ? 'deleteAccount' : 'signOut'} preserves active sync and pending work',
      () async {
        when(() => repo.signOut()).thenThrow(StateError('network'));
        when(
          () => repo.deleteAccount(deleteBusiness: false, password: 'secret'),
        ).thenThrow(StateError('network'));
        await _waitForAuth(container);
        await Future<void>.delayed(Duration.zero);
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        final client = SupabaseClient('http://localhost', 'anon');
        addTearDown(client.dispose);
        final sync = SyncService(
          db: db,
          client: client,
          connectivityCheck: () async => [ConnectivityResult.none],
          scheduleRetry: (_, _) {},
        );
        final bundle = SyncBundle(
          db: db,
          sync: sync,
          businessId: 'b1',
          memberId: 'm1',
        );
        SyncBundleRegistry.instance.replace(bundle);
        addTearDown(disposeSyncBundle);
        await db.enqueue(
          entityType: 'bill',
          entityId: 'pending',
          payload: {'id': 'pending'},
        );
        final controller = container.read(authProvider.notifier);
        clearInteractions(push);
        await expectLater(
          deleting
              ? controller.deleteAccount(password: 'secret')
              : controller.signOut(),
          throwsStateError,
        );
        expect(container.read(authProvider).value?.member?.id, 'm1');
        expect(SyncBundleRegistry.instance.active, same(bundle));
        expect(sync.isActive, isTrue);
        verifyInOrder([push.unregister, () => push.registerForMember('m1')]);
        expect((await db.pendingQueue()).single.entityId, 'pending');
      },
    );
  }

  test(
    'push restore failure does not mask the original account failure',
    () async {
      final original = StateError('account operation failed');
      when(repo.signOut).thenThrow(original);
      await _waitForAuth(container);
      await Future<void>.delayed(Duration.zero);
      when(
        () => push.registerForMember('m1'),
      ).thenThrow(StateError('push unavailable'));
      await expectLater(
        container.read(authProvider.notifier).signOut(),
        throwsA(same(original)),
      );
      expect(container.read(authProvider).value?.member?.id, 'm1');
    },
  );

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

  test(
    'same-member role change detaches the previous privileged cache',
    () async {
      await _waitForAuth(container);
      await Future<void>.delayed(Duration.zero);
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final client = SupabaseClient('http://localhost', 'anon');
      addTearDown(client.dispose);
      final sync = SyncService(
        db: db,
        client: client,
        connectivityCheck: () async => [ConnectivityResult.none],
        scheduleRetry: (_, _) {},
      );
      SyncBundleRegistry.instance.replace(
        SyncBundle(db: db, sync: sync, businessId: 'b1', memberId: 'm1'),
      );
      when(() => repo.peekCachedSession()).thenAnswer((_) async => _session);
      when(() => repo.loadSession()).thenAnswer(
        (_) async => SessionState(
          user: _session.user,
          member: _session.member!.copyWith(role: Role.warehouse),
        ),
      );
      when(() => repo.updateOwnPassword('newpass123')).thenAnswer((_) async {});
      await container
          .read(authProvider.notifier)
          .updateOwnPassword('newpass123');
      expect(container.read(authProvider).value?.member?.role, Role.warehouse);
      expect(SyncBundleRegistry.instance.active, isNull);
      expect(sync.isActive, isFalse);
      await Future<void>.delayed(Duration.zero);
    },
  );

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
    await container
        .read(authProvider.notifier)
        .updateOwnPassword('newpass123', currentPassword: 'oldpass');

    expect(container.read(authProvider).value?.mustChangePassword, isFalse);
  });

  test('signIn surfaces AccountDeactivatedException', () async {
    when(
      () => repo.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => repo.loadSession(),
    ).thenThrow(const AccountDeactivatedException());

    await _waitForAuth(container);
    final controller = container.read(authProvider.notifier);

    expect(
      () => controller.signIn('staff@test.com', 'password123'),
      throwsA(isA<AccountDeactivatedException>()),
    );
  });

  test('keeps cached session when live member fetch fails', () async {
    final load = Completer<SessionState>();
    when(() => repo.peekCachedSession()).thenAnswer((_) async => _session);
    when(() => repo.loadSession()).thenAnswer((_) => load.future);

    container.read(authProvider);
    for (var i = 0; i < 20; i++) {
      if (container.read(authProvider).value?.member?.id == 'm1') break;
      await Future<void>.delayed(Duration.zero);
    }
    expect(container.read(authProvider).value?.isAuthenticated, isTrue);

    load.completeError(Exception('Connection refused'));
    await Future<void>.delayed(Duration.zero);

    final auth = container.read(authProvider);
    expect(auth.hasError, isFalse);
    expect(auth.value?.member?.id, 'm1');
    expect(auth.value?.isAuthenticated, isTrue);
  });
}
