import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../global_search_sheet_test.dart' as search_tests;
import '../web_shell_accessibility_test.dart' as shell_tests;
import '../warehouse_billing_privacy_test.dart' as warehouse_tests;
import '../order_quote_section_test.dart' as order_tests;
import '../notification_bell_test.dart' as notification_tests;

@JS('businessSajiloTestResult')
external set _testResult(JSString value);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.allTestsPassed.future.then((passed) {
    _testResult = jsonEncode({
      'passed': passed,
      'expectedTests': 29,
      'results': binding.results.map(
        (name, result) => MapEntry(name, result.toString()),
      ),
    }).toJS;
  });
  setUpAll(() async {
    final manifest =
        jsonDecode(await rootBundle.loadString('FontManifest.json'))
            as List<dynamic>;
    for (final entry in manifest.cast<Map<String, dynamic>>()) {
      final loader = FontLoader(entry['family'] as String);
      for (final font
          in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
        loader.addFont(rootBundle.load(font['asset'] as String));
      }
      await loader.load();
    }
  });
  group('search', search_tests.main);
  group('shell', shell_tests.main);
  group('warehouse', warehouse_tests.main);
  group('orders', order_tests.main);
  group('notifications', notification_tests.main);
}
