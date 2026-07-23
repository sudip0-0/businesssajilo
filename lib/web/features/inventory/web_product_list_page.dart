import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/paginated_list_state.dart';
import '../../../core/ui/stock_badge.dart';
import '../../../data/repositories/products_repository.dart';
import '../../../domain/models/product.dart';
import '../../../features/inventory/product_detail_screen.dart';
import '../../../features/inventory/product_image.dart';
import '../../../features/inventory/providers.dart';
import '../../layout/web_master_detail.dart';
import '../../theme/web_palette.dart';
import '../../ui/web_empty_state.dart';
import '../../ui/web_search_field.dart';
import '../../ui/web_skeleton.dart';
import '../web_page_scaffold.dart';

String _webRolePrefix(BuildContext context) {
  final segments = GoRouterState.of(context).uri.pathSegments;
  if (segments.isEmpty) return '';
  return '/${segments.first}';
}

class WebProductListPage extends ConsumerStatefulWidget {
  const WebProductListPage({
    super.key,
    this.selectedProductId,
    this.canEdit = false,
    this.canManageStock = false,
  });

  final String? selectedProductId;
  final bool canEdit;
  final bool canManageStock;

  @override
  ConsumerState<WebProductListPage> createState() => _WebProductListPageState();
}

class _WebProductListPageState extends ConsumerState<WebProductListPage> {
  String _query = '';
  PaginatedListState<Product>? _pager;
  final _scrollController = ScrollController();
  late final TextEditingController _searchController;
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialQ = GoRouterState.of(context).uri.queryParameters['q'] ?? '';
      if (initialQ.isNotEmpty) {
        _query = initialQ;
        _searchController.text = initialQ;
      }
      _initPager();
    });
  }

  void _initPager() {
    _pager = PaginatedListState<Product>(
      loadPage: (offset, limit) => ref
          .read(productsRepositoryProvider)
          .list(activeOnly: !_showInactive, offset: offset, limit: limit),
      onChanged: () {
        if (mounted) setState(() {});
      },
    )..attachScrollController(_scrollController);
    _pager!.refresh().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _setShowInactive(bool value) async {
    if (_showInactive == value) return;
    setState(() => _showInactive = value);
    await _pager?.refresh();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final q = GoRouterState.of(context).uri.queryParameters['q'] ?? '';
    if (q != _query) {
      _query = q;
      if (_searchController.text != q) {
        _searchController.text = q;
      }
    }
  }

  List<Product> get _filtered {
    final items = _pager?.items ?? [];
    return items.where((p) {
      return _query.isEmpty ||
          p.name.toLowerCase().contains(_query.toLowerCase()) ||
          (p.sku?.toLowerCase().contains(_query.toLowerCase()) ?? false);
    }).toList();
  }

  void _openProduct(Product product) {
    context.go('${_webRolePrefix(context)}/inventory/${product.id}');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pager = _pager;
    final selectedId = widget.selectedProductId;

    ref.listen<int>(inventoryRevisionProvider, (prev, next) {
      if (prev != next) {
        _pager?.refresh();
      }
    });

    return WebPageScaffold(
      title: l10n.stock,
      actions: [
        if (widget.canEdit) ...[
          FilterChip(
            label: Text(_showInactive ? l10n.hideInactive : l10n.showInactive),
            selected: _showInactive,
            onSelected: _setShowInactive,
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () =>
                context.push('${_webRolePrefix(context)}/inventory/new'),
            icon: const Icon(PhosphorIconsRegular.plus),
            label: Text(l10n.addProduct),
          ),
        ],
      ],
      body: WebMasterDetail(
        hasSelection: selectedId != null,
        list: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: WebSearchField(
                hint: l10n.filterProducts,
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Expanded(child: _buildListBody(l10n, pager)),
          ],
        ),
        detail: selectedId == null
            ? null
            : ProductDetailScreen(
                productId: selectedId,
                canEditProduct: widget.canEdit,
                canManageStock: widget.canManageStock,
                embedded: true,
              ),
      ),
    );
  }

  Widget _buildListBody(
    AppLocalizations l10n,
    PaginatedListState<Product>? pager,
  ) {
    final filtered = _filtered;
    final loading = pager == null || pager.initialLoading;

    if (loading) {
      return const WebListSkeleton();
    }
    if (pager.error != null && pager.items.isEmpty) {
      return WebEmptyState(
        message: l10n.loadingFailed,
        actionLabel: l10n.tryAgain,
        onAction: () => pager.refresh(),
        icon: PhosphorIconsRegular.warning,
      );
    }
    if (filtered.isEmpty) {
      final searching = _query.isNotEmpty;
      return WebEmptyState(
        message: searching ? l10n.noSearchResults : l10n.emptyNoProducts,
        icon: PhosphorIconsRegular.package,
        actionLabel: searching
            ? l10n.clearSearch
            : (widget.canEdit ? l10n.emptyAddFirstProduct : null),
        onAction: searching
            ? () => setState(() {
                _query = '';
                _searchController.clear();
              })
            : (widget.canEdit
                  ? () =>
                        context.push('${_webRolePrefix(context)}/inventory/new')
                  : null),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await pager.refresh();
        ref.invalidate(lowStockCountProvider);
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(BsRadii.lg),
            border: Border.all(color: WebPalette.hairline),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(BsRadii.lg),
            child: ListView.separated(
              controller: _scrollController,
              itemCount: filtered.length + (pager.hasMore ? 1 : 0),
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: WebPalette.hairline),
              itemBuilder: (context, index) {
                if (index >= filtered.length) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: pager.loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : TextButton(
                              onPressed: pager.loadMore,
                              child: Text(l10n.loadMore),
                            ),
                    ),
                  );
                }

                final product = filtered[index];
                final selected = product.id == widget.selectedProductId;
                final sku = product.sku;

                return Material(
                  color: selected ? WebPalette.navyWash : Colors.transparent,
                  child: InkWell(
                    onTap: () => _openProduct(product),
                    hoverColor: WebPalette.paperDeep,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          ProductImage(storagePath: product.imageUrl, size: 40),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: selected
                                            ? WebPalette.navy
                                            : null,
                                      ),
                                ),
                                if (sku != null && sku.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    sku,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: WebPalette.inkSoft),
                                  ),
                                ],
                                if (!product.isActive) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    l10n.inactive,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: WebPalette.inkSoft),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          StockBadge(product: product, compact: true),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
