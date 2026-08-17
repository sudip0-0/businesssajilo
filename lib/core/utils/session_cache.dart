import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/auth_user.dart';
import '../../domain/models/member.dart';
import '../../domain/models/session_state.dart';

const sessionCacheUserIdKey = 'offline_session_auth_user_id';
const sessionCacheEmailKey = 'offline_session_email';
const sessionCacheMemberKey = 'offline_session_member_json';

/// Persists the last authenticated staff session so cold start can restore
/// identity (and open Drift) when Supabase is unreachable.
class SessionCache {
  SessionCache({Future<SharedPreferences> Function()? prefs})
    : _prefs = prefs ?? SharedPreferences.getInstance;

  final Future<SharedPreferences> Function() _prefs;

  Future<void> save(SessionState session) async {
    final user = session.user;
    final member = session.member;
    if (user == null || member == null || !member.isActive) {
      await clear();
      return;
    }
    final prefs = await _prefs();
    await prefs.setString(sessionCacheUserIdKey, user.id);
    await prefs.setString(sessionCacheEmailKey, user.email ?? '');
    await prefs.setString(sessionCacheMemberKey, jsonEncode(member.toJson()));
  }

  Future<SessionState?> loadForUser(String authUserId) async {
    if (authUserId.isEmpty) return null;
    final prefs = await _prefs();
    final storedId = prefs.getString(sessionCacheUserIdKey);
    final memberRaw = prefs.getString(sessionCacheMemberKey);
    if (storedId != authUserId || memberRaw == null || memberRaw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(memberRaw);
      if (decoded is! Map) return null;
      final member = Member.fromJson(Map<String, dynamic>.from(decoded));
      if (!member.isActive || member.authUserId != authUserId) return null;
      final email = prefs.getString(sessionCacheEmailKey);
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
    final prefs = await _prefs();
    await prefs.remove(sessionCacheUserIdKey);
    await prefs.remove(sessionCacheEmailKey);
    await prefs.remove(sessionCacheMemberKey);
  }
}
