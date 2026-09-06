import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/auth_user.dart';
import '../../domain/models/member.dart';
import '../../domain/models/session_state.dart';

const sessionCacheUserIdKey = 'offline_session_auth_user_id';
const sessionCacheEmailKey = 'offline_session_email';
const sessionCacheMemberKey = 'offline_session_member_json';

/// Legacy plain-text keys (SharedPreferences) from before the secure-storage
/// migration; cleared after the first successful move.
const legacySessionCacheUserIdKey = sessionCacheUserIdKey;
const legacySessionCacheEmailKey = sessionCacheEmailKey;
const legacySessionCacheMemberKey = sessionCacheMemberKey;

/// Minimal key/value contract backed by secure storage in production
/// ([FlutterSecureStorage] via [_SecureKeyValueStore]) and by an in-memory
/// map in tests.
abstract class SecureKeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String? value);
  Future<void> delete(String key);
}

class _SecureKeyValueStore implements SecureKeyValueStore {
  final FlutterSecureStorage _storage;

  _SecureKeyValueStore() : _storage = const FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String? value) async {
    if (value == null) {
      await _storage.delete(key: key);
    } else {
      await _storage.write(key: key, value: value);
    }
  }

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// Persists the last authenticated staff session so cold start can restore
/// identity (and open Drift) when Supabase is unreachable.
///
/// Stored in [FlutterSecureStorage] (Keychain / Keystore / encrypted
/// web storage) — the cached member JSON contains role and business
/// membership, which must not be readable or tamperable in plain text.
class SessionCache {
  SessionCache({
    SecureKeyValueStore? storage,
    Future<SharedPreferences> Function()? prefs,
  }) : _storage = storage ?? _SecureKeyValueStore(),
       _prefs = prefs ?? SharedPreferences.getInstance;

  final SecureKeyValueStore _storage;
  final Future<SharedPreferences> Function() _prefs;

  Future<void> save(SessionState session) async {
    final user = session.user;
    final member = session.member;
    if (user == null || member == null || !member.isActive) {
      await clear();
      return;
    }
    await _storage.write(sessionCacheUserIdKey, user.id);
    await _storage.write(sessionCacheEmailKey, user.email ?? '');
    await _storage.write(sessionCacheMemberKey, jsonEncode(member.toJson()));
  }

  Future<SessionState?> loadForUser(String authUserId) async {
    if (authUserId.isEmpty) return null;
    final storedId = await _storage.read(sessionCacheUserIdKey);
    var memberRaw = await _storage.read(sessionCacheMemberKey);
    if (storedId == null && memberRaw == null) {
      // One-time migration from the legacy SharedPreferences cache.
      final migrated = await _migrateLegacy();
      if (!migrated) return null;
      memberRaw = await _storage.read(sessionCacheMemberKey);
    }
    final id = storedId ?? await _storage.read(sessionCacheUserIdKey);
    if (id != authUserId || memberRaw == null || memberRaw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(memberRaw);
      if (decoded is! Map) return null;
      final member = Member.fromJson(Map<String, dynamic>.from(decoded));
      if (!member.isActive || member.authUserId != authUserId) return null;
      final email = await _storage.read(sessionCacheEmailKey);
      return SessionState(
        user: AuthUser(
          id: authUserId,
          email: (email == null || email.isEmpty) ? null : email,
        ),
        member: member,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    await _storage.delete(sessionCacheUserIdKey);
    await _storage.delete(sessionCacheEmailKey);
    await _storage.delete(sessionCacheMemberKey);
  }

  /// Moves a legacy plain-text session into secure storage and wipes the
  /// old keys. Returns true when a usable legacy session was migrated.
  Future<bool> _migrateLegacy() async {
    try {
      final prefs = await _prefs();
      final legacyId = prefs.getString(legacySessionCacheUserIdKey);
      final legacyMember = prefs.getString(legacySessionCacheMemberKey);
      final legacyEmail = prefs.getString(legacySessionCacheEmailKey) ?? '';
      if (legacyId == null || legacyMember == null || legacyMember.isEmpty) {
        return false;
      }
      await _storage.write(sessionCacheUserIdKey, legacyId);
      await _storage.write(sessionCacheEmailKey, legacyEmail);
      await _storage.write(sessionCacheMemberKey, legacyMember);
      await prefs.remove(legacySessionCacheUserIdKey);
      await prefs.remove(legacySessionCacheEmailKey);
      await prefs.remove(legacySessionCacheMemberKey);
      return true;
    } catch (_) {
      return false;
    }
  }
}
