import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/ui/paginated_list_state.dart';
import '../../../core/ui/stock_badge.dart';
import '../../../data/repositories/products_repository.dart';
import '../../../domain/models/category.dart';
import '../../../domain/models/product.dart';
import '../../../features/inventory/product_detail_screen.dart';
import '../../../features/inventory/product_image.dart';
import '../../../features/inventory/providers.dart';
import '../../layout/web_master_detail.dart';
import '../../ui/web_data_table.dart';
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
      child: WebDataTable<Product>(
        columns: [
          DataColumn(label: Text(l10n.productName)),
          DataColumn(label: Text(l10n.sku)),
          DataColumn(label: Text(l10n.categories)),
          DataColumn(label: Text(l10n.stock)),
        ],
        items: filtered,
        selectedId: widget.selectedProductId,
        idFor: (p) => p.id,
        onRowTap: _openProduct,
        rowBuilder: (product, _) => DataRow(
          cells: [
            DataCell(
              Row(
                children: [
                  ProductImage(storagePath: product.imageUrl, size: 32),
                  const SizedBox(width: 10),
                  Expanded(child: Text(product.name)),
                ],
              ),
            ),
            DataCell(Text(product.sku ?? '—')),
            DataCell(Text(product.categoryName ?? '—')),
            DataCell(StockBadge(product: product)),
          ],
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
