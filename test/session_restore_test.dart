import 'dart:async';
import 'dart:io';

import 'package:businesssajilo/core/utils/session_cache.dart';
import 'package:businesssajilo/data/repositories/session_restore.dart';
import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/domain/models/auth_user.dart';
import 'package:businesssajilo/domain/models/member.dart';
import 'package:businesssajilo/domain/models/session_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _user = AuthUser(id: 'u1', email: 'owner@test.com');
const _member = Member(
  id: 'm1',
  businessId: 'b1',
  authUserId: 'u1',
  role: Role.owner,
  displayName: 'Owner',
);

void main() {
  late SessionCache cache;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    cache = SessionCache();
  });

  test('peek returns null when nothing is cached', () async {
    expect(await SessionRestore.peek(user: _user, cache: cache), isNull);
  });

  test('successful fetch is saved and returned', () async {
    final session = await SessionRestore.resolve(
      user: _user,
      cache: cache,
      fetchMember: () async => _member,
    );
    expect(session.member?.id, 'm1');
    expect(await cache.loadForUser('u1'), isNotNull);
  });

  test('timeout falls back to the cached session', () async {
    await cache.save(const SessionState(user: _user, member: _member));
    final session = await SessionRestore.resolve(
      user: _user,
      cache: cache,
      timeout: const Duration(milliseconds: 20),
      fetchMember: () =>
          Future<Member?>.delayed(const Duration(seconds: 2), () => _member),
    );
    expect(session.member?.id, 'm1');
    expect(session.isAuthenticated, isTrue);
  });

  test('socket errors fall back to the cached session', () async {
    await cache.save(const SessionState(user: _user, member: _member));
    final session = await SessionRestore.resolve(
      user: _user,
      cache: cache,
      fetchMember: () => throw const SocketException('Connection refused'),
    );
    expect(session.member?.id, 'm1');
  });

  test('timeout without cache rethrows', () async {
    expect(
      () => SessionRestore.resolve(
        user: _user,
        cache: cache,
        timeout: const Duration(milliseconds: 10),
        fetchMember: () =>
            Future<Member?>.delayed(const Duration(seconds: 2), () => _member),
      ),
      throwsA(isA<TimeoutException>()),
    );
  });

  test('null member is deactivated and clears cache', () async {
    await cache.save(const SessionState(user: _user, member: _member));
    await expectLater(
      SessionRestore.resolve(
        user: _user,
        cache: cache,
        fetchMember: () async => null,
      ),
      throwsA(isA<AccountDeactivatedException>()),
    );
    expect(await cache.loadForUser('u1'), isNull);
  });

  test('null user clears cache and returns empty', () async {
    await cache.save(const SessionState(user: _user, member: _member));
    final session = await SessionRestore.resolve(
      user: null,
      cache: cache,
      fetchMember: () async => _member,
    );
    expect(session.isAuthenticated, isFalse);
    expect(session.user, isNull);
    expect(await cache.loadForUser('u1'), isNull);
  });
}
