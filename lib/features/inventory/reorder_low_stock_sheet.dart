import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/qty_stepper.dart';
import '../../core/ui/submit_action.dart';
import '../../data/repositories/stock_repository.dart';
import '../../domain/models/product.dart';
import '../auth/providers/auth_provider.dart';
import 'providers.dart';

/// Reorder screen for low-stock items: shows a suggested quantity per product
/// (twice the low-stock threshold minus on hand) and records all stock-in
/// movements in one pass.
class ReorderLowStockSheet extends ConsumerStatefulWidget {
  const ReorderLowStockSheet({super.key});

  @override
  ConsumerState<ReorderLowStockSheet> createState() =>
      _ReorderLowStockSheetState();
}

class _ReorderLowStockSheetState extends ConsumerState<ReorderLowStockSheet> {
  final Map<String, int> _qtys = {};
  bool _loading = false;

  static int _suggestedQty(int stockCached, int threshold) {
    final target = threshold * 2;
    final suggested = target - stockCached;
    return suggested < 1 ? 1 : suggested;
  }

  void _ensureQtys(List<Product> products) {
    if (_qtys.isNotEmpty) return;
    for (final product in products) {
      _qtys[product.id] = _suggestedQty(
        product.stockCached,
        product.lowStockThreshold,
      );
    }
  }

  Future<void> _save() async {
    final memberId = ref.read(authProvider).value?.member?.id;
    if (memberId == null) return;
    setState(() => _loading = true);
    await runSubmitAction(
      context,
      action: () async {
        final repo = ref.read(stockRepositoryProvider);
        for (final entry in _qtys.entries) {
          await repo.stockIn(
            productId: entry.key,
            qty: entry.value,
            createdByMemberId: memberId,
          );
        }
        ref.invalidate(lowStockCountProvider);
        ref.invalidate(lowStockProductsProvider);
        ref.invalidate(lowStockAlertsProvider);
        bumpInventoryRevision(ref);
        if (mounted) Navigator.pop(context, true);
      },
    );
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final productsAsync = ref.watch(lowStockProductsProvider);
    final total = _qtys.values.fold<int>(0, (sum, q) => sum + q);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      builder: (context, scrollController) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.reorder,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: productsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => ErrorState(
                  message: l10n.loadingFailed,
                  onRetry: () => ref.invalidate(lowStockProductsProvider),
                ),
                data: (products) {
                  _ensureQtys(products);
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                  Text(
                                    '${l10n.availableStock}: '
                                    '${product.stockCached} · '
                                    '${l10n.suggested}: '
                                    '${_suggestedQty(product.stockCached, product.lowStockThreshold)}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            QtyStepper(
                              value:
                                  _qtys[product.id] ??
                                  _suggestedQty(
                                    product.stockCached,
                                    product.lowStockThreshold,
                                  ),
                              min: 1,
                              onChanged: (v) =>
                                  setState(() => _qtys[product.id] = v),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading || _qtys.isEmpty ? null : _save,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('${l10n.stockIn} · $total'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
