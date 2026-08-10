import 'package:flutter/material.dart';

import '../../../features/billing/bill_detail_screen.dart';

/// Web deep-link host for a customer's own bill (RLS-scoped).
class WebCustomerBillDetailPage extends StatelessWidget {
  const WebCustomerBillDetailPage({super.key, required this.billId});

  final String billId;

  @override
  Widget build(BuildContext context) =>
      BillDetailScreen(billId: billId, embedded: true);
}
