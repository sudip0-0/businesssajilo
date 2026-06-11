import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/push_service_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/sync/sync_providers.dart';
import '../../../domain/models/session_state.dart';

final authProvider =
    NotifierProvider<AuthController, AsyncValue<SessionState>>(AuthController.new);

class AuthController extends Notifier<AsyncValue<SessionState>> {
  StreamSubscription<dynamic>? _subscription;

  @override
  AsyncValue<SessionState> build() {
    final repo = ref.read(authRepositoryProvider);
    _subscription?.cancel();
    _subscription = repo.authStateChanges.listen((_) => unawaited(_reload()));
    ref.onDispose(() => _subscription?.cancel());
    unawaited(_reload());
    return const AsyncValue.loading();
  }

  Future<void> _reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final session = await ref.read(authRepositoryProvider).loadSession();
      await syncBootstrapForSession(session);
      ref.invalidate(syncBundleProvider);
      return session;
    });
    final member = state.value?.member;
    if (member != null) {
      await ref.read(pushServiceProvider).registerForMember(member.id);
    }
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signIn(
            email: email.trim(),
            password: password,
          );
      final session = await ref.read(authRepositoryProvider).loadSession();
      await syncBootstrapForSession(session);
      ref.invalidate(syncBundleProvider);
      return session;
    });
    if (state.hasError) throw state.error!;
  }

  Future<void> signOut() async {
    await ref.read(pushServiceProvider).unregister();
    await disposeSyncBundle();
    ref.invalidate(syncBundleProvider);
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncValue.data(SessionState.empty);
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
        email: email.trim(),
        password: password,
        displayName: displayName.trim(),
        businessName: businessName.trim(),
        businessNameNp: businessNameNp?.trim(),
        phone: phone?.trim(),
        address: address?.trim(),
      );
      await repo.signIn(email: email.trim(), password: password);
      final session = await repo.loadSession();
      await syncBootstrapForSession(session);
      ref.invalidate(syncBundleProvider);
      return session;
    });
    if (state.hasError) throw state.error!;
  }
}
