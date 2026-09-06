import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_log.dart';
import '../../../core/logging/sentry_scope.dart';
import '../../../core/notifications/push_service_provider.dart';
import '../../../core/utils/login_identifier.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/businesses_repository.dart';
import '../../../data/sync/sync_config.dart';
import '../../../data/sync/sync_providers.dart';
import '../../../domain/models/business.dart';
import '../../../domain/models/session_state.dart';

final authProvider = NotifierProvider<AuthController, AsyncValue<SessionState>>(
  AuthController.new,
);

/// Session-scoped business profile — lives with auth, not in the data layer.
final currentBusinessProvider = FutureProvider.autoDispose<Business?>((
  ref,
) async {
  final businessId = ref.watch(authProvider).value?.member?.businessId;
  if (businessId == null) return null;
  try {
    return await ref
        .watch(businessesRepositoryProvider)
        .getById(businessId)
        .timeout(const Duration(seconds: 5));
  } catch (e, st) {
    // Distinguish "no business" from "load failed" — callers watching
    // .value can't retry a swallowed failure.
    AppLog.warn('currentBusinessProvider load failed', e, st);
    return null;
  }
});

class AuthController extends Notifier<AsyncValue<SessionState>> {
  StreamSubscription<dynamic>? _subscription;
  String? _bootstrappedMemberId;
  int _reloadGeneration = 0;

  String? _sessionKey(SessionState session) {
    final member = session.member;
    if (!session.isAuthenticated || member == null) return null;
    return '${session.user?.id}:${member.businessId}:${member.id}:${member.role.name}';
  }

  @override
  AsyncValue<SessionState> build() {
    final repo = ref.read(authRepositoryProvider);
    _subscription?.cancel();
    _subscription = repo.authStateChanges.listen((authState) {
      unawaited(_reload());
    });
    ref.onDispose(() => _subscription?.cancel());
    unawaited(_reload());
    return const AsyncValue.loading();
  }

  /// Sync bootstrap and push registration are best-effort side effects.
  /// They must never fail login/registration/session restore (offline-first).
  void _startSessionSideEffects(SessionState session) {
    if (!session.isAuthenticated || session.member == null) {
      if (_bootstrappedMemberId == null) return;
      _bootstrappedMemberId = null;
      clearSentrySessionScope();
      unawaited(() async {
        final disposing = disposeSyncBundle();
        ref.read(syncBundleVersionProvider.notifier).bump();
        await disposing;
      }());
      return;
    }

    final member = session.member!;
    configureSentrySessionScope(
      memberId: member.id,
      role: member.role,
      syncEnabled: syncEnabledFor(member.role),
    );
    final key = _sessionKey(session);
    if (_bootstrappedMemberId == key) return;
    _bootstrappedMemberId = key;
    unawaited(() async {
      try {
        final disposing = disposeSyncBundle();
        ref.read(syncBundleVersionProvider.notifier).bump();
        await disposing;
        if (_bootstrappedMemberId != key || !ref.mounted) return;
        await syncBootstrapForSession(session);
        if (_bootstrappedMemberId != key || !ref.mounted) return;
        ref.read(syncBundleVersionProvider.notifier).bump();
      } catch (e, st) {
        AppLog.warn(
          'Sync bootstrap failed (will retry on connectivity)',
          e,
          st,
        );
        if (_bootstrappedMemberId == key) {
          _bootstrappedMemberId = null;
        }
      }
      if (!ref.mounted ||
          _sessionKey(state.value ?? SessionState.empty) != key) {
        return;
      }
      try {
        await ref.read(pushServiceProvider).registerForMember(member.id);
      } catch (e, st) {
        AppLog.warn('Push token registration failed', e, st);
      }
    }());
  }

  Future<void> _reload() async {
    final generation = ++_reloadGeneration;
    final repo = ref.read(authRepositoryProvider);
    final cached = await repo.peekCachedSession();
    if (!ref.mounted || generation != _reloadGeneration) return;
    if (cached != null && cached.isAuthenticated) {
      final alreadyShown =
          state.value != null &&
          _sessionKey(state.value!) == _sessionKey(cached);
      state = AsyncValue.data(cached);
      if (!alreadyShown) _startSessionSideEffects(cached);
    } else {
      _startSessionSideEffects(SessionState.empty);
      state = const AsyncValue.loading();
    }

    final result = await tracedOp(
      'auth.load_session',
      'auth',
      () => AsyncValue.guard(repo.loadSession),
    );
    if (!ref.mounted || generation != _reloadGeneration) return;
    if (result.hasError) {
      if (state.value?.isAuthenticated == true &&
          result.error is! AccountDeactivatedException) {
        AppLog.warn(
          'Session refresh failed; keeping cached session',
          result.error,
          result.stackTrace,
        );
        return;
      }
      _startSessionSideEffects(SessionState.empty);
      state = result;
      return;
    }

    final session = result.value ?? SessionState.empty;
    state = AsyncValue.data(session);
    _startSessionSideEffects(session);
  }

  /// [identifier] may be an email address or a Nepali phone number
  /// (phone-created accounts use a synthetic email under the hood).
  Future<void> signIn(String identifier, String password) async {
    _reloadGeneration++;
    _startSessionSideEffects(SessionState.empty);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(authRepositoryProvider)
          .signIn(
            email: loginEmailForIdentifier(identifier),
            password: password,
          );
      return ref.read(authRepositoryProvider).loadSession();
    });
    if (state.hasError) throw state.error!;
    final session = state.value;
    if (session != null) _startSessionSideEffects(session);
  }

  Future<void> sendPasswordResetEmail(String email) {
    return ref
        .read(authRepositoryProvider)
        .sendPasswordResetEmail(email.trim().toLowerCase());
  }

  /// Sets a new password for the signed-in member and refreshes the session
  /// so the forced-change flag clears.
  /// Pass [currentPassword] for voluntary changes (forced reset may omit it).
  Future<void> updateOwnPassword(
    String newPassword, {
    String? currentPassword,
  }) async {
    await ref
        .read(authRepositoryProvider)
        .updateOwnPassword(newPassword, currentPassword: currentPassword);
    await _reload();
    if (state.hasError) throw state.error!;
  }

  /// Deletes the account (or entire business for owners) and clears session.
  /// [password] is always required for re-authentication.
  Future<void> deleteAccount({
    bool deleteBusiness = false,
    String? password,
  }) async {
    final previous = state.value;
    try {
      await ref.read(pushServiceProvider).unregister();
    } catch (e, st) {
      AppLog.warn('Push unregister failed', e, st);
    }
    try {
      await ref
          .read(authRepositoryProvider)
          .deleteAccount(deleteBusiness: deleteBusiness, password: password);
    } catch (_) {
      await _restorePushAfterFailure(previous);
      rethrow;
    }
    _reloadGeneration++;
    await disposeSyncBundle();
    clearSentrySessionScope();
    _bootstrappedMemberId = null;
    ref.read(syncBundleVersionProvider.notifier).bump();
    state = const AsyncValue.data(SessionState.empty);
  }

  Future<void> signOut() async {
    final previous = state.value;
    // Delete the device token server-side while the session is still valid.
    try {
      await ref.read(pushServiceProvider).unregister();
    } catch (e, st) {
      AppLog.warn('Push unregister failed', e, st);
    }
    try {
      await ref.read(authRepositoryProvider).signOut();
    } catch (_) {
      await _restorePushAfterFailure(previous);
      rethrow;
    }
    _reloadGeneration++;
    await disposeSyncBundle();
    clearSentrySessionScope();
    _bootstrappedMemberId = null;
    ref.read(syncBundleVersionProvider.notifier).bump();
    state = const AsyncValue.data(SessionState.empty);
  }

  Future<void> _restorePushAfterFailure(SessionState? previous) async {
    if (!ref.mounted ||
        previous?.member == null ||
        _sessionKey(previous!) !=
            _sessionKey(state.value ?? SessionState.empty)) {
      return;
    }
    try {
      await ref
          .read(pushServiceProvider)
          .registerForMember(previous.member!.id)
          .timeout(const Duration(seconds: 15));
    } catch (e, st) {
      AppLog.warn('Push registration restore failed', e, st);
    }
  }

  Future<void> registerBusiness({
    required String email,
    required String password,
    required String displayName,
    required String businessName,
    String? businessNameNp,
    String? phone,
    String? address,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      await repo.registerBusiness(
        email: email.trim().toLowerCase(),
        password: password,
        displayName: displayName.trim(),
        businessName: businessName.trim(),
        businessNameNp: businessNameNp?.trim(),
        phone: phone?.trim(),
        address: address?.trim(),
      );
      await repo.signIn(email: email.trim().toLowerCase(), password: password);
      return repo.loadSession();
    });
    if (state.hasError) throw state.error!;
    final session = state.value;
    if (session != null) _startSessionSideEffects(session);
  }
}
