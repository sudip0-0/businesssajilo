import 'sync_providers.dart';

/// Explicit lifecycle owner for the active [SyncBundle].
///
/// Replaces a module-level mutable pointer so tenant switch / dispose can be
/// unit-tested without relying on import-order globals.
class SyncBundleRegistry {
  SyncBundleRegistry._();

  static final SyncBundleRegistry instance = SyncBundleRegistry._();

  SyncBundle? _active;

  SyncBundle? get active => _active;

  /// Replaces the active bundle. Caller is responsible for disposing the
  /// previous bundle before calling [replace] when switching tenants.
  void replace(SyncBundle? bundle) {
    _active = bundle;
  }

  /// Disposes sync + DB for the active bundle and clears the registry.
  Future<void> disposeActive() async {
    final current = _active;
    _active = null;
    if (current == null) return;
    current.sync.dispose();
    await current.db.close();
  }
}
