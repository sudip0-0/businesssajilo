import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

enum SyncState { synced, pending, offline }

/// Persistent sync indicator — offline honesty (Design.md §5 of principles).
class SyncBadge extends StatelessWidget {
  const SyncBadge({super.key, required this.state, this.pendingCount = 0});

  final SyncState state;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (color, icon, label) = switch (state) {
      SyncState.synced => (BsColors.success, Icons.cloud_done, l10n.synced),
      SyncState.pending => (
          BsColors.accent,
          Icons.cloud_upload,
          l10n.pendingSync(pendingCount),
        ),
      SyncState.offline => (Colors.grey, Icons.cloud_off, l10n.offline),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}
