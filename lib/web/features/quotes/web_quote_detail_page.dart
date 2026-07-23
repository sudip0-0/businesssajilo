import 'package:flutter/material.dart';

import '../../../features/billing/bill_detail_screen.dart';
import '../../../features/quotes/quote_detail_screen.dart';

/// Web deep-link host for [QuoteDetailScreen].
class WebQuoteDetailPage extends StatelessWidget {
  const WebQuoteDetailPage({super.key, required this.quoteId});

  final String quoteId;

  @override
  Widget build(BuildContext context) => QuoteDetailScreen(quoteId: quoteId);
}

/// Web deep-link host for a customer's own bill (RLS-scoped).
class WebCustomerBillDetailPage extends StatelessWidget {
  const WebCustomerBillDetailPage({super.key, required this.billId});

  final String billId;

  @override
  Widget build(BuildContext context) =>
      BillDetailScreen(billId: billId, embedded: true);
}
