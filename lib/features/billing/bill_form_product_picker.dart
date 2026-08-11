import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/stock_badge.dart';
import '../../core/utils/money.dart';
import '../../domain/models/product.dart';
import '../inventory/product_image.dart';

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
