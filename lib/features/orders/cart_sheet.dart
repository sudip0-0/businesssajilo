import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/ui/qty_stepper.dart';
import '../../data/repositories/orders_repository.dart';
import '../../domain/models/catalog_product.dart';
import '../customers/providers.dart';

class CartSheet extends ConsumerStatefulWidget {
  const CartSheet({
    super.key,
    required this.products,
    required this.quantities,
  });

  final List<CatalogProduct> products;
  final Map<String, int> quantities;

  @override
  ConsumerState<CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends ConsumerState<CartSheet> {
  late final Map<String, int> _qty = Map.from(widget.quantities);
  final _noteController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    final customer = await ref.read(ownCustomerProvider.future);
    if (customer == null) return;

    setState(() => _loading = true);
    try {
      await ref.read(ordersRepositoryProvider).placeOrder(
            customerId: customer.id,
            lines: _qty.entries
                .map(
                  (e) => OrderLineInput(productId: e.key, qty: e.value),
                )
                .toList(),
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.cart, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...widget.products.map((product) {
            final qty = _qty[product.id] ?? 0;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(product.name),
              trailing: QtyStepper(
                value: qty,
                onChanged: (v) => setState(() {
                  if (v <= 0) {
                    _qty.remove(product.id);
                  } else {
                    _qty[product.id] = v;
                  }
                }),
              ),
            );
          }),
          TextField(
            controller: _noteController,
            decoration: InputDecoration(labelText: l10n.orderNote),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loading || _qty.isEmpty ? null : _placeOrder,
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.placeOrder),
          ),
        ],
      ),
    );
  }
}
