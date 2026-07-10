import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/paginated_list_state.dart';
import '../../../core/ui/stock_badge.dart';
import '../../../data/repositories/products_repository.dart';
import '../../../domain/models/category.dart';
import '../../../domain/models/product.dart';
import '../../../features/inventory/product_detail_screen.dart';
import '../../../features/inventory/product_image.dart';
import '../../../features/inventory/providers.dart';
import '../../layout/web_master_detail.dart';
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
  String? _categoryId;
  PaginatedListState<Product>? _pager;
  final _scrollController = ScrollController();
  late final TextEditingController _searchController;

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
          .list(offset: offset, limit: limit),
      onChanged: () {
        if (mounted) setState(() {});
      },
    )..attachScrollController(_scrollController);
    _pager!.refresh().then((_) {
      if (mounted) setState(() {});
    });
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
      final matchesQuery =
          _query.isEmpty ||
          p.name.toLowerCase().contains(_query.toLowerCase()) ||
          (p.sku?.toLowerCase().contains(_query.toLowerCase()) ?? false);
      final matchesCategory =
          _categoryId == null || p.categoryId == _categoryId;
      return matchesQuery && matchesCategory;
    }).toList();
  }

  void _openProduct(Product product) {
    context.go('${_webRolePrefix(context)}/inventory/${product.id}');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final categoriesAsync = ref.watch(categoryListProvider);
    final pager = _pager;
    final selectedId = widget.selectedProductId;

    return WebPageScaffold(
      title: l10n.stock,
      actions: [
        if (widget.canEdit)
          FilledButton.icon(
            onPressed: () =>
                context.push('${_webRolePrefix(context)}/inventory/new'),
            icon: Icon(PhosphorIconsRegular.plus),
            label: Text(l10n.addProduct),
          ),
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
            categoriesAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (categories) => _CategoryChips(
                categories: categories,
                selectedId: _categoryId,
                onSelected: (id) => setState(() => _categoryId = id),
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
      final searching = _query.isNotEmpty || _categoryId != null;
      return WebEmptyState(
        message: searching ? l10n.noSearchResults : l10n.emptyNoProducts,
        icon: PhosphorIconsRegular.package,
        actionLabel: searching
            ? l10n.clearSearch
            : (widget.canEdit ? l10n.emptyAddFirstProduct : null),
        onAction: searching
            ? () => setState(() {
                _query = '';
                _categoryId = null;
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
            border: Border.all(color: BsColors.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(BsRadii.lg),
            child: ListView.separated(
              controller: _scrollController,
              itemCount: filtered.length + (pager.hasMore ? 1 : 0),
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: BsColors.border),
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
                final meta = [
                  if (product.sku != null && product.sku!.isNotEmpty)
                    product.sku!,
                  if (product.categoryName != null) product.categoryName!,
                ].join(' · ');

                return Material(
                  color: selected
                      ? BsColors.primary.withValues(alpha: 0.06)
                      : Colors.transparent,
                  child: InkWell(
                    onTap: () => _openProduct(product),
                    hoverColor: BsColors.rowHover,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          ProductImage(
                            storagePath: product.imageUrl,
                            size: 40,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: selected
                                            ? BsColors.primary
                                            : null,
                                      ),
                                ),
                                if (meta.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    meta,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: BsColors.outline),
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

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (categories.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          FilterChip(
            label: Text(l10n.allCategories),
            selected: selectedId == null,
            onSelected: (_) => onSelected(null),
          ),
          const SizedBox(width: 8),
          ...categories.map(
            (c) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(c.name),
                selected: selectedId == c.id,
                onSelected: (_) => onSelected(c.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
