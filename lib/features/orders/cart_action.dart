import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/ui/adaptive_sheet.dart';
import 'cart_provider.dart';
import 'cart_sheet.dart';
import 'catalog_screen.dart';
import 'providers.dart';

/// Top-right cart icon with a badge of distinct item count.
class CartAction extends ConsumerWidget {
  const CartAction({super.key});

  Future<void> _openCart(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.cartEmpty)));
      return;
    }
    final catalog = await ref.read(catalogListProvider.future);
    if (!context.mounted) return;
    final placed = await showAdaptiveSheet<bool>(
      context: context,
      title: l10n.placeOrder,
      child: CartSheet(
        products: catalog.where((p) => cart.containsKey(p.id)).toList(),
        quantities: Map.from(cart),
      ),
    );
    if (placed == true) {
      ref.read(cartProvider.notifier).clear();
      ref.invalidate(catalogListProvider);
      ref.invalidate(ownOrderListProvider);
      ref.invalidate(ownOrderCountProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final count = ref.watch(cartDistinctCountProvider);

    return IconButton(
      tooltip: l10n.cart,
      onPressed: () => _openCart(context, ref),
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        child: const Icon(Icons.shopping_cart_outlined),
      ),
    );
  }
}
