import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/member.dart';
import '../../domain/models/session_state.dart';
import '../remote/supabase_provider.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

/// Thrown when a Supabase user exists but has no active member row
/// (deactivated by the business owner, or orphaned).
class AccountDeactivatedException implements Exception {
  const AccountDeactivatedException();

  @override
  String toString() => 'AccountDeactivatedException: account deactivated';
}

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient? _client;

  Stream<AuthState> get authStateChanges =>
      _client?.auth.onAuthStateChange ?? const Stream.empty();

  Future<SessionState> loadSession() async {
    final client = _client;
    if (client == null) return SessionState.empty;

    final user = client.auth.currentUser;
    if (user == null) return SessionState.empty;

    final row = await client
        .from('members')
        .select()
        .eq('auth_user_id', user.id)
        .eq('is_active', true)
        .maybeSingle();

    if (row == null) {
      // Orphan session: auth user without an active member row. Sign out so
      // the stale session cannot linger, and surface a distinct error.
      try {
        await client.auth.signOut();
      } catch (_) {
        // Best effort — offline sign-out failures shouldn't mask the cause.
      }
      throw const AccountDeactivatedException();
    }

    return SessionState(
      user: user,
      member: Member.fromJson(row),
    );
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
  Future<void> updateOwnPassword(String newPassword) async {
    final client = _requireClient();
    await client.auth.updateUser(UserAttributes(password: newPassword));
    await client.rpc('clear_must_change_password');
  }

  /// Deletes the current account via the `delete-account` Edge Function.
  /// [deleteBusiness] is only valid for owners and purges the whole tenant.
  Future<void> deleteAccount({bool deleteBusiness = false}) async {
    final client = _requireClient();
    final response = await client.functions.invoke(
      'delete-account',
      body: {'mode': deleteBusiness ? 'business' : 'self'},
    );
    if (response.status != 200) {
      final data = response.data;
      final message = data is Map ? data['error']?.toString() : null;
      throw AuthException(message ?? 'Account deletion failed');
    }
    // Local session is now orphaned; sign out best-effort.
    try {
      await client.auth.signOut();
    } catch (_) {
      // The auth user no longer exists; ignore sign-out errors.
    }
  }

  Future<void> signOut() async {
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
