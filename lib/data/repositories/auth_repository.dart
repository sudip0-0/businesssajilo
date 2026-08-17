// AuthRepository intentionally keeps Supabase SDK usage inline — it is the
// session/auth boundary and is not split into lib/data/remote/ like data repos.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../core/utils/app_prefs.dart';
import '../../core/utils/session_cache.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/models/member.dart';
import '../../domain/models/session_state.dart';
import '../remote/supabase_provider.dart';
import 'session_restore.dart';

export 'session_restore.dart' show AccountDeactivatedException;

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

class AuthRepository {
  AuthRepository(
    this._client, {
    SessionCache? sessionCache,
    Duration memberFetchTimeout = sessionMemberFetchTimeout,
  }) : _sessionCache = sessionCache ?? SessionCache(),
       _memberFetchTimeout = memberFetchTimeout;

  final SupabaseClient? _client;
  final SessionCache _sessionCache;
  final Duration _memberFetchTimeout;

  Stream<AuthState> get authStateChanges =>
      _client?.auth.onAuthStateChange ?? const Stream.empty();

  AuthUser? get _currentAuthUser {
    final user = _client?.auth.currentUser;
    if (user == null) return null;
    return AuthUser(id: user.id, email: user.email);
  }

  /// Last cached staff session for [currentUser], without hitting the network.
  Future<SessionState?> peekCachedSession() {
    return SessionRestore.peek(user: _currentAuthUser, cache: _sessionCache);
  }

  Future<SessionState> loadSession() async {
    final client = _client;
    if (client == null) {
      await _sessionCache.clear();
      return SessionState.empty;
    }

    try {
      return await SessionRestore.resolve(
        user: _currentAuthUser,
        cache: _sessionCache,
        timeout: _memberFetchTimeout,
        fetchMember: () => _fetchActiveMember(client),
      );
    } on AccountDeactivatedException {
      try {
        await client.auth.signOut();
      } catch (_) {
        // Best effort — offline sign-out failures shouldn't mask the cause.
      }
      rethrow;
    }
  }

  Future<Member?> _fetchActiveMember(SupabaseClient client) async {
    final user = client.auth.currentUser;
    if (user == null) return null;
    final row = await client
        .from('members')
        .select()
        .eq('auth_user_id', user.id)
        .eq('is_active', true)
        .maybeSingle();
    if (row == null) return null;
    try {
      await NotificationMutePrefs.fromNotificationPrefs(
        row['notification_prefs'],
      ).save();
    } catch (_) {
      // Local mute cache is best-effort; login must still succeed.
    }
    return Member.fromJson(Map<String, dynamic>.from(row as Map));
  }

  Future<void> signIn({required String email, required String password}) async {
    final client = _requireClient();
    await client.auth.signInWithPassword(email: email, password: password);
  }

  /// Sends a password recovery email (owner self-service reset).
  Future<void> sendPasswordResetEmail(String email) async {
    final client = _requireClient();
    await client.auth.resetPasswordForEmail(email);
  }

  /// Sets a new password for the signed-in user and clears the
  /// owner-initiated forced-change flag.
  ///
  /// When [currentPassword] is provided (voluntary change), re-authenticates
  /// first so a stolen session alone cannot change the password.
  Future<void> updateOwnPassword(
    String newPassword, {
    String? currentPassword,
  }) async {
    final client = _requireClient();
    if (currentPassword != null && currentPassword.isNotEmpty) {
      final email = client.auth.currentUser?.email;
      if (email == null || email.isEmpty) {
        throw const AuthException('Account has no email for re-authentication');
      }
      await client.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );
    }
    await client.auth.updateUser(UserAttributes(password: newPassword));
    await client.rpc('clear_must_change_password');
  }

  /// Deletes the current account via the `delete-account` Edge Function.
  /// [deleteBusiness] is only valid for owners and purges the whole tenant.
  /// Both self and business deletion require [password] for re-authentication.
  Future<void> deleteAccount({
    bool deleteBusiness = false,
    String? password,
  }) async {
    final client = _requireClient();
    if (password == null || password.isEmpty) {
      throw AuthException(
        deleteBusiness
            ? 'Password required to delete business'
            : 'Password required to delete account',
      );
    }
    final body = <String, dynamic>{
      'mode': deleteBusiness ? 'business' : 'self',
      'password': password,
    };
    final response = await client.functions.invoke(
      'delete-account',
      body: body,
    );
    if (response.status != 200) {
      final data = response.data;
      final message = data is Map ? data['error']?.toString() : null;
      throw AuthException(message ?? 'Account deletion failed');
    }
    await _sessionCache.clear();
    // Local session is now orphaned; sign out best-effort.
    try {
      await client.auth.signOut();
    } catch (_) {
      // The auth user no longer exists; ignore sign-out errors.
    }
  }

  Future<void> signOut() async {
    await _sessionCache.clear();
    final client = _client;
    if (client == null) return;
    await client.auth.signOut();
  }

  Future<({String businessId, String memberId})> registerBusiness({
    required String email,
    required String password,
    required String displayName,
    required String businessName,
    String? businessNameNp,
    String? phone,
    String? address,
  }) async {
    final client = _requireClient();
    final response = await client.functions.invoke(
      'register-business',
      body: {
        'email': email,
        'password': password,
        'displayName': displayName,
        'businessName': businessName,
        'businessNameNp': ?businessNameNp,
        'phone': ?phone,
        'address': ?address,
      },
    );

    if (response.status != 200) {
      final data = response.data;
      final message = data is Map ? data['error']?.toString() : null;
      throw AuthException(message ?? 'Registration failed');
    }

    final data = response.data as Map<String, dynamic>;
    return (
      businessId: data['businessId'] as String,
      memberId: data['memberId'] as String,
    );
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw const AuthException(
        'Supabase not configured. Pass SUPABASE_URL and SUPABASE_ANON_KEY.',
      );
    }
    return client;
  }
}
