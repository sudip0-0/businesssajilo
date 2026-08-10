import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/adaptive_sheet.dart';
import '../../core/ui/bs_snackbar.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/money_text.dart';
import '../../core/ui/paginated_list_state.dart';
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
import 'stock_adjust_sheet.dart';
import 'stock_in_sheet.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
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
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  PaginatedListState<StockMovement>? _movementsPager;
  String? _pagerProductId;
  StockMovementType? _movementTypeFilter;
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _initMovementsPager() {
    final productId = widget.productId;
    if (_pagerProductId == productId) return;
    _pagerProductId = productId;
    _movementsPager = PaginatedListState<StockMovement>(
      loadPage: (offset, limit) => ref
          .read(stockRepositoryProvider)
          .listMovements(productId, offset: offset, limit: limit),
      onChanged: () {
        if (mounted) setState(() {});
      },
    )..attachScrollController(_scrollController);
    _movementsPager!.refresh();
  }

  void _setMovementTypeFilter(StockMovementType? type) {
    if (_movementTypeFilter == type) return;
    setState(() => _movementTypeFilter = type);
    if (type != null) {
      // Type filters apply over the loaded ledger, so load it fully first.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _loadAllMovementsForFilter(),
      );
    }
  }

  Future<void> _loadAllMovementsForFilter() async {
    await _movementsPager?.loadAll();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final productId = widget.productId;
    final productAsync = ref.watch(productDetailProvider(productId));

    return productAsync.when(
      loading: () => widget.embedded
          ? const Center(child: CircularProgressIndicator())
          : Scaffold(
              appBar: AppBar(),
              body: const Center(child: CircularProgressIndicator()),
            ),
      error: (e, _) => widget.embedded
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
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _initMovementsPager(),
        );
        final body = ListView(
          controller: _scrollController,
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
            if (widget.canManageStock) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: () => _stockIn(context, product.id),
                      icon: const Icon(Icons.add_box_outlined),
                      label: Text(l10n.stockIn),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _adjust(context, product.id),
                      icon: const Icon(Icons.tune),
                      label: Text(l10n.stockAdjust),
                    ),
                  ),
                ],
              ),
            ],
            if (widget.canEditProduct) ...[
              const SizedBox(height: 12),
              if (!product.isActive) Chip(label: Text(l10n.inactive)),
              if (widget.embedded) ...[
                const SizedBox(height: 8),
                if (product.isActive)
                  OutlinedButton.icon(
                    onPressed: () =>
                        _deactivate(context, product.id, l10n),
                    icon: const Icon(Icons.visibility_off_outlined),
                    label: Text(l10n.deactivateProduct),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () => _activate(context, product.id, l10n),
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
            _buildMovements(l10n, product.stockCached),
          ],
        );

        if (widget.embedded) return body;
        return Scaffold(
          appBar: AppBar(
            title: Text(product.name),
            actions: [
              if (widget.canEditProduct)
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
              if (widget.canEditProduct)
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
                      ? _deactivate(context, product.id, l10n)
                      : _activate(context, product.id, l10n),
                ),
            ],
          ),
          body: body,
        );
      },
    );
  }

  Widget _buildMovements(AppLocalizations l10n, int productStock) {
    final pager = _movementsPager;
    final chips = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (type, label) in [
            (null, l10n.allStock),
            (StockMovementType.stockIn, l10n.movementTypeStockIn),
            (StockMovementType.adjust, l10n.movementTypeAdjust),
            (StockMovementType.dispatch, l10n.movementTypeDispatch),
            (StockMovementType.return_, l10n.movementTypeReturn),
          ])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(label),
                selected: _movementTypeFilter == type,
                onSelected: (_) => _setMovementTypeFilter(type),
              ),
            ),
        ],
      ),
    );

    if (pager == null || pager.initialLoading) {
      return Column(
        children: [
          chips,
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }
    if (pager.error != null && pager.items.isEmpty) {
      return Column(children: [chips, Text(l10n.loadingFailed)]);
    }

    // Running balance: the newest loaded movement's balance-after equals the
    // current on-hand stock; each older movement subtracts its own delta.
    var balance = productStock;
    final rows = <Widget>[];
    for (final m in pager.items) {
      if (_movementTypeFilter == null || m.type == _movementTypeFilter) {
        rows.add(_MovementTile(movement: m, balance: balance));
      }
      balance -= m.qtyDelta;
    }

    if (rows.isEmpty) {
      return Column(children: [chips, Text(l10n.noMovements)]);
    }
    return Column(
      children: [
        chips,
        ...rows,
        if (pager.hasMore)
          Center(
            child: pager.loading
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  )
                : TextButton(
                    onPressed: pager.loadMore,
                    child: Text(l10n.loadMore),
                  ),
          ),
      ],
    );
  }

  Future<void> _stockIn(BuildContext context, String productId) async {
    final saved = await showAdaptiveSheet<bool>(
      context: context,
      title: AppLocalizations.of(context).stockIn,
      child: StockInSheet(productId: productId),
    );
    if (saved == true) {
      ref.invalidate(productDetailProvider(productId));
      await _movementsPager?.refresh();
      ref.invalidate(productListProvider);
      ref.invalidate(lowStockCountProvider);
      bumpInventoryRevision(ref);
    }
  }

  Future<void> _adjust(BuildContext context, String productId) async {
    final saved = await showAdaptiveSheet<bool>(
      context: context,
      title: AppLocalizations.of(context).stockAdjust,
      child: StockAdjustSheet(productId: productId),
    );
    if (saved == true) {
      ref.invalidate(productDetailProvider(productId));
      await _movementsPager?.refresh();
      ref.invalidate(productListProvider);
      ref.invalidate(lowStockCountProvider);
      bumpInventoryRevision(ref);
    }
  }

  Future<void> _deactivate(
    BuildContext context,
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
    if (context.mounted && !widget.embedded) Navigator.pop(context, true);
  }

  Future<void> _activate(
    BuildContext context,
    String id,
    AppLocalizations l10n,
  ) async {
    await ref.read(productsRepositoryProvider).activate(id);
    ref.invalidate(productDetailProvider(id));
    ref.invalidate(productListProvider);
    bumpInventoryRevision(ref);
    if (context.mounted && !widget.embedded) {
      showBsSnackBar(context, message: l10n.reactivate);
    }
  }
}

class _MovementTile extends StatelessWidget {
  const _MovementTile({required this.movement, required this.balance});

  final StockMovement movement;
  final int balance;

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
      trailing: Text(
        '${l10n.balance}: $balance',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
