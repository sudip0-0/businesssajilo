import 'package:businesssajilo/core/config/env.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../web/router/web_router.dart';
import 'mobile_router.dart';

bool get _useWebRouter => kIsWeb || Env.forceWebUi;

/// Platform-aware router: web gets nested URL routes; mobile keeps flat routes.
final routerProvider = Provider<GoRouter>((ref) {
  if (_useWebRouter) {
    return ref.watch(webRouterProvider);
  }
  return ref.watch(mobileRouterProvider);
});
