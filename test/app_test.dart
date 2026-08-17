import 'package:businesssajilo/app.dart';
import 'package:businesssajilo/domain/models/session_state.dart';
import 'package:businesssajilo/features/auth/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _UnauthenticatedAuth extends AuthController {
  @override
  AsyncValue<SessionState> build() => const AsyncValue.data(SessionState.empty);
}

void main() {
  testWidgets('app boots to login when unauthenticated', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authProvider.overrideWith(_UnauthenticatedAuth.new)],
        child: const BusinessSajiloApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Email or phone number'), findsOneWidget);
  });
}
