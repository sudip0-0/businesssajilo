import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/env.dart';
import '../../domain/enums.dart';
import '../auth/providers/auth_provider.dart';

/// Resolves the bill detail route for the running platform.
///
/// Mobile uses the flat `/bill/:billId` deep link; web keeps URL nesting via
/// the role-prefixed `/billing/:billId` routes (e.g. `/owner/billing/:id`).
/// [forceWeb] overrides platform detection for tests.
String billDetailPath(Role? role, String billId, {bool forceWeb = false}) {
  if (forceWeb || kIsWeb || Env.forceWebUi) {
    final base = switch (role) {
      Role.owner => '/owner',
      Role.sales => '/sales',
      Role.warehouse => '/warehouse',
      Role.customer => '/customer',
      null => '/owner',
    };
    return '$base/billing/$billId';
  }
  return '/bill/$billId';
}

/// Pushes the bill detail page from ledger-style lists.
///
/// Resolves to `true` when the bill changed while viewing it (e.g. items were
/// returned), so callers can refresh their ledger.
Future<bool?> pushBillDetail(
  BuildContext context,
  WidgetRef ref,
  String billId,
) {
  final role = ref.read(authProvider).value?.member?.role;
  return context.push<bool>(billDetailPath(role, billId));
}
