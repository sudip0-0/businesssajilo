import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/stock_badge.dart';
import '../../core/utils/money.dart';
import '../../domain/models/product.dart';
import '../inventory/product_image.dart';

/// Mobile product search + picker for bill forms.
class BillFormProductPicker extends StatelessWidget {
  const BillFormProductPicker({
    super.key,
    required this.products,
    required this.query,
    required this.onQueryChanged,
    required this.onProductSelected,
  });

  final List<Product> products;
  final String query;
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
            decoration: InputDecoration(
              hintText: l10n.filterProducts,
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: (v) => onQueryChanged(v.trim()),
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: products.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                leading: ProductImage(storagePath: product.imageUrl),
                title: Text(product.name),
                subtitle: Text(
                  formatNpr(Paisa(product.referencePrice), showPaisa: false),
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
