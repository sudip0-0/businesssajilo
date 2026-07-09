import 'package:businesssajilo/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app boots to login when Supabase not configured', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: BusinessSajiloApp()));
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Email or phone number'), findsOneWidget);
  });
}
