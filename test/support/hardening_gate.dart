import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// True when local hardening gate is enforced (CI or `HARDENING_GATE=1`).
bool get hardeningGateEnabled {
  const fromDefine = bool.fromEnvironment('HARDENING_GATE', defaultValue: false);
  if (fromDefine) return true;
  return Platform.environment['HARDENING_GATE'] == '1';
}

/// Skips the current test unless [hardeningGateEnabled]; fails the gate when
/// enabled and [condition] is false.
void requireForHardeningGate(bool condition, String message) {
  if (condition) return;
  if (hardeningGateEnabled) {
    fail(message);
  }
  markTestSkipped('$message (set HARDENING_GATE=1 to enforce)');
}
