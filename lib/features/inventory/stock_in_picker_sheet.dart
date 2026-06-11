import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/ui/error_state.dart';
import '../../domain/models/product.dart';
import 'providers.dart';
import 'stock_in_sheet.dart';

class StockInPickerSheet extends ConsumerWidget {
  const StockInPickerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final productsAsync = ref.watch(productListProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l10n.stockIn, style: Theme.of(context).textTheme.titleLarge),
          ),
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorState(
                message: l10n.loadingFailed,
                onRetry: () => ref.invalidate(productListProvider),
              ),
              data: (products) => ListView.builder(
                controller: scrollController,
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return ListTile(
                    title: Text(product.name),
                    subtitle: Text('${product.stockCached} ${product.unit}'),
                    onTap: () => _openStockIn(context, ref, product),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openStockIn(
    BuildContext context,
    WidgetRef ref,
    Product product,
  ) async {
    Navigator.pop(context);
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => StockInSheet(productId: product.id),
    );
    if (saved == true) {
      ref.invalidate(productListProvider);
      ref.invalidate(lowStockCountProvider);
    }
  }
}
