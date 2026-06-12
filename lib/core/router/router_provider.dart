import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../web/router/web_router.dart';
import 'mobile_router.dart';

/// Platform-aware router: web gets nested URL routes; mobile keeps flat routes.
final routerProvider = Provider<GoRouter>((ref) {
  if (kIsWeb) {
    return ref.watch(webRouterProvider);
  }
  return ref.watch(mobileRouterProvider);
});
