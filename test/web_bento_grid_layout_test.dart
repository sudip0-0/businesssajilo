import 'package:businesssajilo/web/layout/web_bento_grid.dart';
import 'package:businesssajilo/web/theme/web_tokens.dart';
import 'package:businesssajilo/web/ui/web_stat_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('WebBentoGrid lays out in a scroll view without assertion', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [WebTokens.light]),
        home: Scaffold(
          body: RefreshIndicator(
            onRefresh: () async {},
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: WebBentoGrid(
                children: [
                  const WebStatTile(label: 'My Orders', value: '0'),
                  const WebStatTile(label: 'My Dues', value: '₹ 10,000'),
                  WebBentoTile(
                    height: 188,
                    onTap: () {},
                    child: const Text('Catalog'),
                  ),
                  WebBentoTile(
                    height: 188,
                    onTap: () {},
                    child: const Text('My Orders'),
                  ),
                  WebBentoTile(
                    height: 188,
                    onTap: () {},
                    child: const Text('My Dues'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('MY ORDERS'), findsOneWidget);
    expect(find.text('MY DUES'), findsOneWidget);
    expect(find.text('Catalog'), findsOneWidget);
  });
}
