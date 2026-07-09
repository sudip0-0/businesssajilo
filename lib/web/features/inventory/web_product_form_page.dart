import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../domain/models/product.dart';
import '../../../features/inventory/product_form_screen.dart';
import '../../../features/inventory/providers.dart';
import '../web_page_scaffold.dart';

class WebProductFormPage extends ConsumerStatefulWidget {
  const WebProductFormPage({
    super.key,
    this.product,
    this.productId,
    this.inventoryListPath = '/owner/inventory',
  });

  final Product? product;
  final String? productId;
  final String inventoryListPath;

  @override
  ConsumerState<WebProductFormPage> createState() => _WebProductFormPageState();
}

class _WebProductFormPageState extends ConsumerState<WebProductFormPage> {
  final _formKey = GlobalKey<ProductFormScreenState>();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final resolvedProduct = widget.product ??
        (widget.productId != null
            ? ref.watch(productDetailProvider(widget.productId!)).value
            : null);
    final isEdit = resolvedProduct != null;

    if (widget.productId != null && resolvedProduct == null) {
      return WebPageScaffold(
        title: l10n.editProduct,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return WebPageScaffold(
      title: isEdit ? l10n.editProduct : l10n.addProduct,
      breadcrumbs: [
        l10n.inventory,
        isEdit ? l10n.editProduct : l10n.addProduct,
      ],
      actions: [
        OutlinedButton.icon(
          onPressed: () {
            if (isEdit) {
              context.go(
                '${widget.inventoryListPath}/${resolvedProduct.id}',
              );
            } else {
              context.go(widget.inventoryListPath);
            }
          },
          icon: Icon(PhosphorIconsRegular.x),
          label: Text(l10n.cancel),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: () => _formKey.currentState?.submit(),
          icon: Icon(PhosphorIconsRegular.floppyDisk, size: 18),
          label: Text(l10n.save),
        ),
      ],
      body: ProductFormScreen(
        key: _formKey,
        product: resolvedProduct,
        embedded: true,
      ),
    );
  }
}

/// Call after a successful save to refresh inventory lists and navigate back.
void webProductFormSaved(
  BuildContext context,
  WidgetRef ref, {
  Product? product,
  String listPath = '/owner/inventory',
}) {
  ref.invalidate(productListProvider);
  ref.invalidate(lowStockCountProvider);
  if (product != null) {
    ref.invalidate(productDetailProvider(product.id));
    context.go('$listPath/${product.id}');
  } else {
    context.go(listPath);
  }
}
