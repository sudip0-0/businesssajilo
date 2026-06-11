import 'package:businesssajilo/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app boots and toggles locale EN -> NP', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: BusinessSajiloApp()));
    await tester.pumpAndSettle();

    expect(find.text('Your business, the easy way.'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.translate));
    await tester.pumpAndSettle();

    expect(find.text('तपाईंको व्यवसाय, सजिलो तरिकाले।'), findsOneWidget);
  });
}
