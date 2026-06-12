import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../features/orders/fulfillment_list_screen.dart';
import '../../../features/orders/order_detail_screen.dart';
import '../../layout/web_master_detail.dart';
import '../web_page_scaffold.dart';

class WebFulfillmentPage extends StatelessWidget {
  const WebFulfillmentPage({super.key, this.selectedOrderId});

  final String? selectedOrderId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return WebPageScaffold(
      title: l10n.fulfillment,
      body: WebMasterDetail(
        hasSelection: selectedOrderId != null,
        list: const FulfillmentListScreen(),
        detail: selectedOrderId != null
            ? OrderDetailScreen(
                orderId: selectedOrderId!,
                embedded: true,
              )
            : null,
      ),
    );
  }
}
