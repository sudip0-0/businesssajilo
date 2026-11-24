import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/preferences/saved_filters_store.dart';
import 'auth_provider.dart';

/// Current authenticated tenant/member/role scope for saved preferences.
final currentFilterScopeProvider = Provider<FilterScope?>((ref) {
  final member = ref.watch(authProvider.select((s) => s.value?.member));
  if (member == null) return null;
  final scope = FilterScope(
    businessId: member.businessId,
    memberId: member.id,
    role: member.role,
  );
  return scope.isValid ? scope : null;
});
