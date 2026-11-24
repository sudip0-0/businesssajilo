import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/enums.dart';
import '../auth/providers/auth_provider.dart';
import 'cart_draft_store.dart';

/// Customer shopping cart: productId → quantity.
///
/// Persists items, order note, and client-generated [placementId] across app
/// restarts, strictly scoped to the signed-in customer `(businessId, memberId)`.
class CartNotifier extends Notifier<Map<String, int>> {
  static const _uuid = Uuid();

  String placementId = _uuid.v4();
  String _note = '';
  bool _restoredFromDraft = false;
  bool _mutatedInSession = false;
  int _hydrationGeneration = 0;
  CartDraftScope? _scope;
  Future<void> _hydrationFuture = Future<void>.value();

  String get note => _note;
  bool get restoredFromDraft => _restoredFromDraft;
  Future<void> get hydrationComplete => _hydrationFuture;

  @override
  Map<String, int> build() {
    final member = ref.watch(authProvider.select((s) => s.value?.member));
    final nextScope = member != null && member.role == Role.customer
        ? CartDraftScope(businessId: member.businessId, memberId: member.id)
        : null;
    _scope = nextScope != null && nextScope.isValid ? nextScope : null;
    placementId = _uuid.v4();
    _note = '';
    _restoredFromDraft = false;
    _mutatedInSession = false;

    final generation = ++_hydrationGeneration;
    if (_scope != null) {
      _hydrationFuture = _hydrate(_scope!, generation);
      unawaited(_hydrationFuture);
    } else {
      _hydrationFuture = Future<void>.value();
    }
    return {};
  }

  Future<void> _hydrate(CartDraftScope scope, int generation) async {
    final draft = await ref.read(cartDraftStoreProvider).load(scope);
    if (!ref.mounted ||
        generation != _hydrationGeneration ||
        _mutatedInSession ||
        draft == null) {
      return;
    }
    placementId = draft.placementId;
    _note = draft.note;
    _restoredFromDraft = true;
    state = Map<String, int>.from(draft.quantities);
  }

  void _persist() {
    final scope = _scope;
    if (scope == null) return;
    unawaited(
      ref
          .read(cartDraftStoreProvider)
          .save(
            scope,
            CartDraft(
              placementId: placementId,
              quantities: Map<String, int>.from(state),
              note: _note,
              updatedAt: DateTime.now().toUtc(),
            ),
          ),
    );
  }

  /// Number of distinct products in the cart.
  int get distinctCount => state.length;

  void setQty(String productId, int qty) {
    _mutatedInSession = true;
    final next = Map<String, int>.from(state);
    if (qty <= 0) {
      next.remove(productId);
    } else {
      next[productId] = qty;
    }
    state = next;
    _persist();
  }

  void addOne(String productId) {
    setQty(productId, (state[productId] ?? 0) + 1);
  }

  void setNote(String value) {
    if (_note == value) return;
    _mutatedInSession = true;
    _note = value;
    _persist();
  }

  void clear() {
    _mutatedInSession = true;
    _restoredFromDraft = false;
    placementId = _uuid.v4();
    _note = '';
    state = {};
    final scope = _scope;
    if (scope != null) {
      unawaited(ref.read(cartDraftStoreProvider).clear(scope));
    }
  }

  void replaceAll(Map<String, int> quantities, {String? note}) {
    _mutatedInSession = true;
    if (note != null) _note = note;
    state = Map<String, int>.from(quantities)
      ..removeWhere((_, qty) => qty <= 0);
    _persist();
  }
}

final cartProvider = NotifierProvider<CartNotifier, Map<String, int>>(
  CartNotifier.new,
);

final cartDistinctCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).length;
});
