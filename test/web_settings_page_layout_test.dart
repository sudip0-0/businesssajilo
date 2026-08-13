import 'package:businesssajilo/core/l10n/app_localizations.dart';
import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/domain/models/business.dart';
import 'package:businesssajilo/domain/models/member.dart';
import 'package:businesssajilo/domain/models/session_state.dart';
import 'package:businesssajilo/features/auth/providers/auth_provider.dart';
import 'package:businesssajilo/web/features/settings/web_settings_page.dart';
import 'package:businesssajilo/web/theme/web_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FixedAuth extends AuthController {
  _FixedAuth(this.session);
  final SessionState session;

  @override
  AsyncValue<SessionState> build() => AsyncValue.data(session);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'BusinessSajilo',
      packageName: 'com.example.businesssajilo',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  testWidgets('settings page scrolls instead of overflowing on a short window', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(
            () => _FixedAuth(
              const SessionState(
                member: Member(
                  id: 'me',
                  businessId: 'biz',
                  authUserId: 'auth-me',
                  role: Role.owner,
                  displayName: 'Owner',
                ),
              ),
            ),
          ),
          currentBusinessProvider.overrideWith(
            (ref) async => const Business(
              id: 'biz',
              name: 'Test Shop',
              nameNp: 'टेस्ट',
              address: 'Kathmandu',
              phone: '9800000000',
              subscriptionPlan: 'free',
            ),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData(extensions: const [WebTokens.light]),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const WebSettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Phone'), findsOneWidget);
    expect(find.text('Mute order chat notifications'), findsOneWidget);
    expect(find.text('Plan'), findsOneWidget);

    await tester.ensureVisible(find.text('Plan'));
    expect(tester.takeException(), isNull);
  });
}
