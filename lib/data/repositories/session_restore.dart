import 'dart:async';

import '../../core/errors/app_failure.dart';
import '../../core/utils/session_cache.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/models/member.dart';
import '../../domain/models/session_state.dart';

/// Thrown when a live member fetch returns no active row.
class AccountDeactivatedException implements Exception {
  const AccountDeactivatedException();

  @override
  String toString() => 'AccountDeactivatedException: account deactivated';
}

/// How long session restore waits on the live `members` row before falling
/// back to the last cached staff session.
const sessionMemberFetchTimeout = Duration(seconds: 5);

/// Resolves [SessionState] from a live member fetch, with a cached fallback
/// when the database is unreachable. Extracted so restore policy is unit-tested
/// without the Supabase SDK.
class SessionRestore {
  static Future<SessionState> resolve({
    required AuthUser? user,
    required Future<Member?> Function() fetchMember,
    required SessionCache cache,
    Duration timeout = sessionMemberFetchTimeout,
  }) async {
    if (user == null) {
      await cache.clear();
      return SessionState.empty;
    }

    try {
      final member = await fetchMember().timeout(timeout);
      if (member == null || !member.isActive) {
        await cache.clear();
        throw const AccountDeactivatedException();
      }
      final session = SessionState(user: user, member: member);
      await cache.save(session);
      return session;
    } on AccountDeactivatedException {
      rethrow;
    } catch (error) {
      if (!_isTransientFetchError(error)) rethrow;
      final cached = await cache.loadForUser(user.id);
      if (cached != null && cached.isAuthenticated) return cached;
      rethrow;
    }
  }

  static Future<SessionState?> peek({
    required AuthUser? user,
    required SessionCache cache,
  }) async {
    if (user == null) return null;
    final cached = await cache.loadForUser(user.id);
    if (cached == null || !cached.isAuthenticated) return null;
    return cached;
  }

  static bool _isTransientFetchError(Object error) {
    if (error is TimeoutException) return true;
    if (error is AppFailureNetwork) return true;
    return AppFailure.from(error) is AppFailureNetwork;
  }
}
