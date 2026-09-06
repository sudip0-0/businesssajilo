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

/// In-memory fake standing in for the secure-storage API used by SessionCache.
class _FakeSecureStorage implements SecureKeyValueStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) => Future.value(values[key]);

  @override
  Future<void> write(String key, String? value) async =>
      value == null ? values.remove(key) : (values[key] = value);

  @override
  Future<void> delete(String key) async => values.remove(key);
}

void main() {
  late _FakeSecureStorage storage;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    storage = _FakeSecureStorage();
  });

  SessionCache cache() => SessionCache(storage: storage);

  test('save then loadForUser restores the same session', () async {
    await cache().save(_session);
    final loaded = await cache().loadForUser('u1');
    expect(loaded?.user?.id, 'u1');
    expect(loaded?.user?.email, 'owner@test.com');
    expect(loaded?.member?.id, 'm1');
    expect(loaded?.member?.role, Role.owner);
    expect(loaded?.isAuthenticated, isTrue);
  });

  test('loadForUser returns null for a different auth user', () async {
    await cache().save(_session);
    expect(await cache().loadForUser('other'), isNull);
  });

  test('clear removes the cached session', () async {
    await cache().save(_session);
    await cache().clear();
    expect(await cache().loadForUser('u1'), isNull);
  });

  test('save of empty session clears the cache', () async {
    await cache().save(_session);
    await cache().save(SessionState.empty);
    expect(await cache().loadForUser('u1'), isNull);
  });

  test('legacy plain-text session is migrated to secure storage', () async {
    // Seed the legacy SharedPreferences keys exactly as the old build wrote
    // them, then verify the first load migrates and wipes them.
    SharedPreferences.setMockInitialValues({
      legacySessionCacheUserIdKey: 'u1',
      legacySessionCacheEmailKey: 'owner@test.com',
      legacySessionCacheMemberKey:
          '{"id":"m1","business_id":"b1",'
          '"auth_user_id":"u1","role":"owner","display_name":"Owner",'
          '"is_active":true}',
    });

    final loaded = await cache().loadForUser('u1');
    expect(loaded?.member?.role, Role.owner);

    // Secure storage now holds it.
    expect(storage.values[sessionCacheUserIdKey], 'u1');

    // Legacy keys wiped.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(legacySessionCacheUserIdKey), isNull);
    expect(prefs.getString(legacySessionCacheMemberKey), isNull);
  });
}
