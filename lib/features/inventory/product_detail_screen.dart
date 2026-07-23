import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/money_text.dart';
import '../../core/ui/stock_badge.dart';
import '../../core/utils/bs_date.dart';
import '../../core/utils/money.dart';
import '../../data/repositories/products_repository.dart';
import '../../data/repositories/stock_repository.dart';
import '../../domain/enums.dart';
import '../../domain/models/stock_movement.dart';
import 'product_form_screen.dart';
import 'product_image.dart';
import 'providers.dart';
import '../../core/ui/adaptive_sheet.dart';
import 'stock_adjust_sheet.dart';
import 'stock_in_sheet.dart';

final movementListProvider = FutureProvider.autoDispose
    .family<List<StockMovement>, String>((ref, productId) {
      return ref.watch(stockRepositoryProvider).listMovements(productId);
    });

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({
    super.key,
    required this.productId,
    required this.canManageStock,
    required this.canEditProduct,
    this.embedded = false,
  });

  final String productId;
  final bool canManageStock;
  final bool canEditProduct;
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final productAsync = ref.watch(productDetailProvider(productId));
    final movementsAsync = ref.watch(movementListProvider(productId));

    return productAsync.when(
      loading: () => embedded
          ? const Center(child: CircularProgressIndicator())
          : Scaffold(
              appBar: AppBar(),
              body: const Center(child: CircularProgressIndicator()),
            ),
      error: (e, _) => embedded
          ? ErrorState(
              message: l10n.loadingFailed,
              onRetry: () => ref.invalidate(productDetailProvider(productId)),
            )
          : Scaffold(
              appBar: AppBar(),
              body: ErrorState(
                message: l10n.loadingFailed,
                onRetry: () => ref.invalidate(productDetailProvider(productId)),
              ),
            ),
      data: (product) {
        final body = ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                ProductImage(storagePath: product.imageUrl, size: 72),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (product.nameNp != null) Text(product.nameNp!),
                      const SizedBox(height: 8),
                      StockBadge(product: product),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (product.sku != null)
              ListTile(title: Text(l10n.sku), trailing: Text(product.sku!)),
            ListTile(title: Text(l10n.unit), trailing: Text(product.unit)),
            ListTile(
              title: Text(l10n.costPrice),
              trailing: MoneyText(Paisa(product.costPrice)),
            ),
            ListTile(
              title: Text(l10n.referencePrice),
              trailing: MoneyText(Paisa(product.referencePrice)),
            ),
            if (canManageStock) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: () => _stockIn(context, ref, product.id),
                      icon: const Icon(Icons.add_box_outlined),
                      label: Text(l10n.stockIn),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _adjust(context, ref, product.id),
                      icon: const Icon(Icons.tune),
                      label: Text(l10n.stockAdjust),
                    ),
                  ),
                ],
              ),
            ],
            if (canEditProduct) ...[
              const SizedBox(height: 12),
              if (!product.isActive) Chip(label: Text(l10n.inactive)),
              if (embedded) ...[
                const SizedBox(height: 8),
                if (product.isActive)
                  OutlinedButton.icon(
                    onPressed: () =>
                        _deactivate(context, ref, product.id, l10n),
                    icon: const Icon(Icons.visibility_off_outlined),
                    label: Text(l10n.deactivateProduct),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () => _activate(context, ref, product.id, l10n),
                    icon: const Icon(Icons.visibility_outlined),
                    label: Text(l10n.reactivate),
                  ),
              ],
            ],
            const SizedBox(height: 16),
            Text(
              l10n.movementHistory,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            movementsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(l10n.loadingFailed),
              data: (movements) => movements.isEmpty
                  ? Text(l10n.noMovements)
                  : Column(
                      children: movements
                          .map((m) => _MovementTile(movement: m))
                          .toList(),
                    ),
            ),
          ],
        );

        if (embedded) return body;
        return Scaffold(
          appBar: AppBar(
            title: Text(product.name),
            actions: [
              if (canEditProduct)
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: l10n.editProduct,
                  onPressed: () async {
                    final saved = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductFormScreen(product: product),
                      ),
                    );
                    if (saved == true) {
                      ref.invalidate(productDetailProvider(productId));
                      ref.invalidate(productListProvider);
                      if (context.mounted) Navigator.pop(context, true);
                    }
                  },
                ),
              if (canEditProduct)
                IconButton(
                  icon: Icon(
                    product.isActive
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  tooltip: product.isActive
                      ? l10n.deactivateProduct
                      : l10n.reactivate,
                  onPressed: () => product.isActive
                      ? _deactivate(context, ref, product.id, l10n)
                      : _activate(context, ref, product.id, l10n),
                ),
            ],
          ),
          body: body,
        );
      },
    );
  }

  Future<void> _stockIn(
    BuildContext context,
    WidgetRef ref,
    String productId,
  ) async {
    final l10n = AppLocalizations.of(context);
    final saved = await showAdaptiveSheet<bool>(
      context: context,
      title: l10n.stockIn,
      child: StockInSheet(productId: productId),
    );
    if (saved == true) {
      ref.invalidate(productDetailProvider(productId));
      ref.invalidate(movementListProvider(productId));
      ref.invalidate(productListProvider);
      ref.invalidate(lowStockCountProvider);
      bumpInventoryRevision(ref);
    }
  }

  Future<void> _adjust(
    BuildContext context,
    WidgetRef ref,
    String productId,
  ) async {
    final l10n = AppLocalizations.of(context);
    final saved = await showAdaptiveSheet<bool>(
      context: context,
      title: l10n.stockAdjust,
      child: StockAdjustSheet(productId: productId),
    );
    if (saved == true) {
      ref.invalidate(productDetailProvider(productId));
      ref.invalidate(movementListProvider(productId));
      ref.invalidate(productListProvider);
      ref.invalidate(lowStockCountProvider);
      bumpInventoryRevision(ref);
    }
  }

  Future<void> _deactivate(
    BuildContext context,
    WidgetRef ref,
    String id,
    AppLocalizations l10n,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deactivateProduct),
        content: Text(l10n.deactivateProductConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.deactivate),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(productsRepositoryProvider).deactivate(id);
    ref.invalidate(productDetailProvider(id));
    ref.invalidate(productListProvider);
    bumpInventoryRevision(ref);
    if (context.mounted && !embedded) Navigator.pop(context, true);
  }

  Future<void> _activate(
    BuildContext context,
    WidgetRef ref,
    String id,
    AppLocalizations l10n,
  ) async {
    await ref.read(productsRepositoryProvider).activate(id);
    ref.invalidate(productDetailProvider(id));
    ref.invalidate(productListProvider);
    bumpInventoryRevision(ref);
    if (context.mounted && !embedded) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.reactivate)));
    }
  }
}

class _MovementTile extends StatelessWidget {
  const _MovementTile({required this.movement});

  final StockMovement movement;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final typeLabel = switch (movement.type) {
      StockMovementType.stockIn => l10n.movementTypeStockIn,
      StockMovementType.adjust => l10n.movementTypeAdjust,
      StockMovementType.dispatch => l10n.movementTypeDispatch,
      StockMovementType.return_ => l10n.movementTypeReturn,
    };
    final sign = movement.qtyDelta > 0 ? '+' : '';
    final when = movement.createdAt != null
        ? BsDate.both(movement.createdAt!)
        : '';

    return ListTile(
      leading: Icon(
        movement.qtyDelta > 0 ? Icons.arrow_upward : Icons.arrow_downward,
        color: movement.qtyDelta > 0 ? BsColors.success : BsColors.danger,
      ),
      title: Text('$typeLabel: $sign${movement.qtyDelta}'),
      subtitle: Text(
        [
          if (movement.reason != null) movement.reason!,
          if (movement.createdByName != null) movement.createdByName!,
          when,
        ].where((s) => s.isNotEmpty).join(' · '),
      ),
    );
  }
}
