import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/notifications/notification_target.dart';
import '../../domain/enums.dart';
import '../../domain/models/notification_item.dart';

/// Navigates to the screen targeted by a notification using go_router,
/// respecting [role] permissions. Targets the role cannot access are ignored.
void openWebNotificationTarget(
  BuildContext context,
  NotificationItem item, {
  Role? role,
}) {
  if (role == null) return;

  final target = resolveNotificationTarget(item, role: role);
  if (target is! NotificationNavigate) return;

  final webPath = webPathForNotificationTarget(
    role: role,
    mobilePath: target.path,
  );
  if (webPath != null) {
    context.go(webPath);
  }
}
