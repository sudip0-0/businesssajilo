import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/notifications/notification_target.dart';
import '../../domain/enums.dart';
import '../../domain/models/notification_item.dart';

/// Navigates to the screen targeted by a notification, respecting [role]
/// permissions. Targets the role cannot access are ignored silently.
void openNotificationTarget(
  BuildContext context,
  NotificationItem item, {
  Role? role,
}) {
  final target = resolveNotificationTarget(item, role: role);
  if (target is NotificationNavigate) {
    context.push(target.path);
  }
}
