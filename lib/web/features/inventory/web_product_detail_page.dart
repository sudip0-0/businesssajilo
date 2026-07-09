import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../domain/enums.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/inventory/product_detail_screen.dart';
import '../../../features/inventory/providers.dart';
import '../web_page_scaffold.dart';

class WebProductDetailPage extends ConsumerWidget {
  const WebProductDetailPage({
    super.key,
    required this.productId,
    this.inventoryListPath = '/owner/inventory',
  });

  final String productId;
  final String inventoryListPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final role = ref.watch(authProvider).value?.member?.role;
    final productAsync = ref.watch(productDetailProvider(productId));
    final canEdit = role?.canManageProducts ?? false;
    final canManageStock = role?.canManageStock ?? false;

    return WebPageScaffold(
      title: productAsync.maybeWhen(
        data: (p) => p.name,
        orElse: () => l10n.products,
      ),
      breadcrumbs: [l10n.inventory, productId.substring(0, 8)],
      actions: [
        OutlinedButton.icon(
          onPressed: () => context.go(inventoryListPath),
          icon: Icon(PhosphorIconsRegular.arrowLeft),
          label: Text(l10n.inventory),
        ),
        if (canEdit) ...[
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () => context.push('$inventoryListPath/$productId/edit'),
            icon: Icon(PhosphorIconsRegular.pencilSimple),
            label: Text(l10n.editProduct),
          ),
        ],
      ],
      body: ProductDetailScreen(
        productId: productId,
        canEditProduct: canEdit,
        canManageStock: canManageStock,
        embedded: true,
      ),
    );
  }
}

String webInventoryListPath(Role? role) => switch (role) {
  Role.owner => '/owner/inventory',
  Role.sales => '/sales/inventory',
  Role.warehouse => '/warehouse/stock',
  Role.customer => '/customer/catalog',
  null => '/login',
};
