import 'package:businesssajilo/core/l10n/app_localizations.dart';
import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/domain/models/bill.dart';
import 'package:businesssajilo/features/reports/dashboard/dashboard_activity_feed.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('bill activity uses shop name not bill number', (tester) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    const bill = Bill(
      id: 'b1',
      businessId: 'biz',
      billNo: 'INV-0142',
      status: BillStatus.paid,
      createdBy: 'u1',
      customerShopName: 'Sagarmatha Traders',
    );

    final items = buildDashboardActivityFeed(l10n: l10n, bills: [bill]);
    expect(items, hasLength(1));
    expect(items.single.text, 'New bill created for Sagarmatha Traders');
    expect(items.single.text, isNot(contains('INV-0142')));
  });

  testWidgets('walk-in bills use the walk-in label', (tester) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    const bill = Bill(
      id: 'b1',
      businessId: 'biz',
      billNo: 'INV-0001',
      status: BillStatus.paid,
      createdBy: 'u1',
    );

    final items = buildDashboardActivityFeed(l10n: l10n, bills: [bill]);
    expect(items.single.text, 'New bill created for Walk-in Customer');
  });
}
