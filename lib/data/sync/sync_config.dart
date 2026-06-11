import 'package:flutter/foundation.dart';

import '../../domain/enums.dart';

bool syncEnabledFor(Role? role) {
  if (role == null || role == Role.customer) return false;
  return !kIsWeb;
}
