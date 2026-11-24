import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Tenant + member scope for customer cart drafts.
class CartDraftScope {
  const CartDraftScope({required this.businessId, required this.memberId});

  final String businessId;
  final String memberId;

  bool get isValid =>
      businessId.trim().isNotEmpty && memberId.trim().isNotEmpty;

  String get storageKey =>
      'bs_cart_draft_v1::${businessId.trim()}::${memberId.trim()}';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CartDraftScope &&
            other.businessId == businessId &&
            other.memberId == memberId;
  }

  @override
  int get hashCode => Object.hash(businessId, memberId);
}

/// Durable customer cart draft surviving app restarts.
class CartDraft {
  const CartDraft({
    required this.placementId,
    required this.quantities,
    this.note = '',
    this.updatedAt,
  });

  final String placementId;
  final Map<String, int> quantities;
  final String note;
  final DateTime? updatedAt;

  bool get isEmpty => quantities.isEmpty && note.trim().isEmpty;

  Map<String, dynamic> toJson() => {
    'placementId': placementId,
    'quantities': quantities,
    'note': note,
    'updatedAt': (updatedAt ?? DateTime.now().toUtc()).toIso8601String(),
  };

  factory CartDraft.fromJson(Map<String, dynamic> json) {
    final rawId = json['placementId'];
    final placementId = rawId is String && rawId.trim().isNotEmpty
        ? rawId.trim()
        : _uuid.v4();
    final rawQty = json['quantities'];
    final quantities = <String, int>{};
    if (rawQty is Map) {
      for (final entry in rawQty.entries) {
        final key = entry.key.toString().trim();
        final value = entry.value;
        final qty = value is int
            ? value
            : (value is num ? value.toInt() : int.tryParse('$value'));
        if (key.isNotEmpty && qty != null && qty > 0) {
          quantities[key] = qty;
        }
      }
    }
    final rawNote = json['note'];
    final note = rawNote is String ? rawNote : '';
    final rawUpdated = json['updatedAt'];
    final updatedAt = rawUpdated is String
        ? DateTime.tryParse(rawUpdated)
        : null;
    return CartDraft(
      placementId: placementId,
      quantities: quantities,
      note: note,
      updatedAt: updatedAt,
    );
  }
}

/// Persists customer cart drafts scoped by `(businessId, memberId)`.
class CartDraftStore {
  const CartDraftStore();

  Future<CartDraft?> load(CartDraftScope? scope) async {
    if (scope == null || !scope.isValid) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(scope.storageKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final draft = CartDraft.fromJson(Map<String, dynamic>.from(decoded));
      return draft.isEmpty ? null : draft;
    } catch (_) {
      return null;
    }
  }

  Future<void> save(CartDraftScope? scope, CartDraft draft) async {
    if (scope == null || !scope.isValid) return;
    if (draft.isEmpty) {
      await clear(scope);
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(scope.storageKey, jsonEncode(draft.toJson()));
    } catch (_) {
      // Best-effort draft persistence must not block cart actions.
    }
  }

  Future<void> clear(CartDraftScope? scope) async {
    if (scope == null || !scope.isValid) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(scope.storageKey);
    } catch (_) {}
  }
}

final cartDraftStoreProvider = Provider<CartDraftStore>(
  (ref) => const CartDraftStore(),
);
