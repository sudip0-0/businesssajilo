import 'package:businesssajilo/core/utils/session_cache.dart';
import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/domain/models/auth_user.dart';
import 'package:businesssajilo/domain/models/member.dart';
import 'package:businesssajilo/domain/models/session_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('save then loadForUser restores the same session', () async {
    final cache = SessionCache();
    await cache.save(_session);
    final loaded = await cache.loadForUser('u1');
    expect(loaded?.user?.id, 'u1');
    expect(loaded?.user?.email, 'owner@test.com');
    expect(loaded?.member?.id, 'm1');
    expect(loaded?.member?.role, Role.owner);
    expect(loaded?.isAuthenticated, isTrue);
  });

  test('loadForUser returns null for a different auth user', () async {
    final cache = SessionCache();
    await cache.save(_session);
    expect(await cache.loadForUser('other'), isNull);
  });

  test('clear removes the cached session', () async {
    final cache = SessionCache();
    await cache.save(_session);
    await cache.clear();
    expect(await cache.loadForUser('u1'), isNull);
  });

  test('save of empty session clears the cache', () async {
    final cache = SessionCache();
    await cache.save(_session);
    await cache.save(SessionState.empty);
    expect(await cache.loadForUser('u1'), isNull);
  });
}
