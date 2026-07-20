import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Customer shopping cart: productId → quantity.
class CartNotifier extends Notifier<Map<String, int>> {
  @override
  Map<String, int> build() => {};

  /// Number of distinct products in the cart.
  int get distinctCount => state.length;

  void setQty(String productId, int qty) {
    final next = Map<String, int>.from(state);
    if (qty <= 0) {
      next.remove(productId);
    } else {
      next[productId] = qty;
    }
    state = next;
  }

  void addOne(String productId) {
    setQty(productId, (state[productId] ?? 0) + 1);
  }

  void clear() => state = {};

  void replaceAll(Map<String, int> quantities) {
    state = Map<String, int>.from(quantities)
      ..removeWhere((_, qty) => qty <= 0);
  }
}

final cartProvider = NotifierProvider<CartNotifier, Map<String, int>>(
  CartNotifier.new,
);

final cartDistinctCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).length;
});
