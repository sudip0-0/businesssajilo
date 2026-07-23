import 'package:flutter/material.dart';

import '../../data/sync/sync_models.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

export '../../data/sync/sync_models.dart' show SyncState;

/// Persistent sync indicator — offline honesty (Design.md §5 of principles).
class SyncBadge extends StatelessWidget {
  const SyncBadge({super.key, required this.state, this.pendingCount = 0});

  final SyncState state;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (color, icon, label) = switch (state) {
      SyncState.synced => (
        BsSemanticColors.syncSynced,
        Icons.cloud_done,
        l10n.synced,
      ),
      SyncState.pending => (
        BsSemanticColors.syncPending,
        Icons.cloud_upload,
        l10n.pendingSync(pendingCount),
      ),
      SyncState.offline => (
        BsSemanticColors.syncOffline,
        Icons.cloud_off,
        l10n.offline,
      ),
      SyncState.incomplete => (
        BsSemanticColors.syncPending,
        Icons.cloud_sync_outlined,
        l10n.syncIncompleteContinue,
      ),
    };
    return Semantics(
      label: '${l10n.syncStatus}: $label',
      liveRegion: state == SyncState.incomplete,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(color: color, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
