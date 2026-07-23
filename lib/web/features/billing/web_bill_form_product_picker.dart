import 'package:flutter/material.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../domain/models/product.dart';
import '../../theme/web_palette.dart';
import '../../ui/web_search_field.dart';

/// Inline product search + suggestion list for web bill forms.
class WebBillFormProductPicker extends StatelessWidget {
  const WebBillFormProductPicker({
    super.key,
    required this.l10n,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.suggestions,
    required this.onProductSelected,
  });

  final AppLocalizations l10n;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final List<Product> suggestions;
  final ValueChanged<Product> onProductSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 36,
          child: Text(
            '…',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: WebPalette.inkSoft),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WebSearchField(
                controller: controller,
                focusNode: focusNode,
                hint: l10n.filterProducts,
                onChanged: onChanged,
              ),
              if (suggestions.isNotEmpty)
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(BsRadii.lg),
                  child: Column(
                    children: [
                      for (final p in suggestions)
                        ListTile(
                          dense: true,
                          title: Text(p.name),
                          subtitle: Text(
                            formatNpr(
                              Paisa(p.referencePrice),
                              showPaisa: false,
                            ),
                          ),
                          onTap: () => onProductSelected(p),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
