// Design preview harness for the POS-style bill form — realistic mock data,
// no backend required. Simulated latency makes the debounced, focus-safe
// search behaviour observable.
//
// Run:
//   flutter run -t tool/design_preview/bill_form_preview.dart -d web-server --web-port 52202
//
// Dev-only tool; nothing here ships in the app bundle.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:businesssajilo/core/l10n/app_localizations.dart';
import 'package:businesssajilo/domain/models/customer.dart';
import 'package:businesssajilo/domain/models/product.dart';
import 'package:businesssajilo/features/customers/providers.dart';
import 'package:businesssajilo/features/inventory/providers.dart';
import 'package:businesssajilo/web/features/billing/web_bill_form_content.dart';
import 'package:businesssajilo/web/features/web_page_scaffold.dart';
import 'package:businesssajilo/web/theme/web_theme.dart';

const _mockLatency = Duration(milliseconds: 250);

final _products = <Product>[
  const Product(id: 'p1', businessId: 'b1', name: 'Amul Cheese 100g', unit: 'packet', referencePrice: 15000, stockCached: 24),
  const Product(id: 'p2', businessId: 'b1', name: 'Amul Kool Coffee 200ml', unit: 'bottle', referencePrice: 6500, stockCached: 3, lowStockThreshold: 6),
  const Product(id: 'p3', businessId: 'b1', name: 'Chicken Breast', unit: 'kg', referencePrice: 55000, stockCached: 18),
  const Product(id: 'p4', businessId: 'b1', name: 'Khukuri Beer 650ml', unit: 'bottle', referencePrice: 45000, stockCached: 60),
  const Product(id: 'p5', businessId: 'b1', name: 'Ruslan Vodka 750ml', unit: 'bottle', referencePrice: 165000, stockCached: 12),
  const Product(id: 'p6', businessId: 'b1', name: 'Sprite 250ml', unit: 'bottle', referencePrice: 5000, stockCached: 48),
  const Product(id: 'p7', businessId: 'b1', name: 'Tuborg Beer 650ml', unit: 'bottle', referencePrice: 43000, stockCached: 0),
  const Product(id: 'p8', businessId: 'b1', name: 'Wai Wai Noodles', unit: 'packet', referencePrice: 2500, stockCached: 120),
  const Product(id: 'p9', businessId: 'b1', name: 'Everest Masala 50g', unit: 'packet', referencePrice: 4000, stockCached: 30),
];

final _customers = <Customer>[
  const Customer(id: 'c1', businessId: 'b1', memberId: 'm1', shopName: 'Sagarmatha Traders', contactName: 'Ramesh Shrestha', phone: '9841234567', balanceDue: 1850000),
  const Customer(id: 'c2', businessId: 'b1', memberId: 'm2', shopName: 'Aarati Suppliers', phone: '9851098765'),
  const Customer(id: 'c3', businessId: 'b1', memberId: 'm3', shopName: 'Himalayan General Store', contactName: 'Bishnu Prasad', balanceDue: 3478000),
  const Customer(id: 'c4', businessId: 'b1', memberId: 'm4', shopName: 'New Road Kirana Pasal'),
  const Customer(id: 'c5', businessId: 'b1', memberId: 'm5', shopName: 'Bishal Bazaar Store', balanceDue: 720000),
];

void main() {
  runApp(
    ProviderScope(
      overrides: [
        productListProvider.overrideWith((ref, query) async {
          await Future<void>.delayed(_mockLatency);
          final q = query.trim().toLowerCase();
          return _products
              .where((p) => q.isEmpty || p.name.toLowerCase().contains(q))
              .toList();
        }),
        customerListProvider.overrideWith((ref, query) async {
          await Future<void>.delayed(_mockLatency);
          final q = query.trim().toLowerCase();
          return _customers
              .where((c) => q.isEmpty || c.shopName.toLowerCase().contains(q))
              .toList();
        }),
      ],
      child: const BillFormPreviewApp(),
    ),
  );
}

class BillFormPreviewApp extends StatelessWidget {
  const BillFormPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bill Form Preview',
      debugShowCheckedModeBanner: false,
      theme: WebTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(
        body: WebPageScaffold(
          title: 'New Sale',
          subtitle: 'Create a new customer bill.',
          breadcrumbs: ['Billing', 'New Sale'],
          body: WebBillFormContent(),
        ),
      ),
    );
  }
}
