import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/stock_badge.dart';
import '../../core/utils/money.dart';
import '../../domain/models/product.dart';
import '../inventory/product_image.dart';
import '../inventory/providers.dart';

/// Mobile product search + picker for bill forms.
///
/// The text field's controller and focus node are hoisted by the parent and
/// the list keeps showing the last loaded products while a query is in
/// flight, so typing never unmounts the field or steals its focus. The parent
/// must clear [products] when the typed query no longer matches the loaded
/// results so stale catalog rows do not flash before "no matches".
class BillFormProductPicker extends StatelessWidget {
  const BillFormProductPicker({
    super.key,
    required this.products,
    required this.controller,
    required this.focusNode,
    required this.refreshing,
    required this.onQueryChanged,
    required this.onProductSelected,
  });

  final List<Product> products;
  final TextEditingController controller;
  final FocusNode focusNode;

  /// True while a fresh list is loading for the current query.
  final bool refreshing;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<Product> onProductSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            BsSpacing.lg,
            BsSpacing.sm,
            BsSpacing.lg,
            0,
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              hintText: l10n.filterProducts,
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: onQueryChanged,
          ),
        ),
        if (refreshing) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: products.isEmpty
              ? Center(
                  child: refreshing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          l10n.noSearchResults,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                )
              : ListView.separated(
                  itemCount: products.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ListTile(
                      leading: ProductImage(storagePath: product.imageUrl),
                      title: Text(product.name),
                      subtitle: Text(
                        formatNpr(
                          Paisa(product.referencePrice),
                          showPaisa: false,
                        ),
                      ),
                      trailing: StockBadge(product: product),
                      onTap: () => onProductSelected(product),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Self-contained product search sheet so typing never depends on the parent
/// bill form rebuilding (the overlay is a different route).
class BillFormProductPickerSheet extends ConsumerStatefulWidget {
  const BillFormProductPickerSheet({super.key, required this.onSelected});

  final ValueChanged<Product> onSelected;

  @override
  ConsumerState<BillFormProductPickerSheet> createState() =>
      _BillFormProductPickerSheetState();
}

class _BillFormProductPickerSheetState
    extends ConsumerState<BillFormProductPickerSheet> {
  static const _searchDebounce = Duration(milliseconds: 300);

  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  String _query = '';
  List<Product> _lastProducts = const [];
  String _lastQuery = '';
  bool _loadedOnce = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onQueryChanged(String raw) {
    _debounce?.cancel();
    final query = raw.trim();
    setState(() {});
    if (query == _query) return;
    _debounce = Timer(_searchDebounce, () {
      if (mounted) setState(() => _query = query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    ref.listen(productListProvider(_query), (_, next) {
      final value = next.value;
      if (value != null) {
        setState(() {
          _lastProducts = value;
          _lastQuery = _query;
          _loadedOnce = true;
        });
      }
    });

    final productsAsync = ref.watch(productListProvider(_query));
    final liveQuery = _controller.text.trim();
    final products = liveQuery == _lastQuery
        ? (productsAsync.value ?? _lastProducts)
        : const <Product>[];
    final refreshing =
        (liveQuery.isNotEmpty && liveQuery != _lastQuery) ||
        (liveQuery == _query && productsAsync.isLoading && _loadedOnce);
    final height = MediaQuery.sizeOf(context).height * 0.78;
    final inset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                BsSpacing.lg,
                0,
                BsSpacing.lg,
                BsSpacing.sm,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.addItem,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            Expanded(
              child: BillFormProductPicker(
                products: products,
                controller: _controller,
                focusNode: _focus,
                refreshing: refreshing,
                onQueryChanged: _onQueryChanged,
                onProductSelected: widget.onSelected,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
