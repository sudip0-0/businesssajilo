import 'package:flutter/material.dart';

import '../../data/sync/sync_models.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

export '../../data/sync/sync_models.dart' show SyncState;

/// Icon, color, and label for a [SyncState].
class SyncBadgeAppearance {
  const SyncBadgeAppearance({
    required this.color,
    required this.icon,
    required this.label,
  });

  final Color color;
  final IconData icon;
  final String label;

  factory SyncBadgeAppearance.from({
    required AppLocalizations l10n,
    required SyncState state,
    int pendingCount = 0,
  }) {
    return switch (state) {
      SyncState.synced => SyncBadgeAppearance(
        color: BsSemanticColors.syncSynced,
        icon: Icons.cloud_done,
        label: l10n.synced,
      ),
      SyncState.pending => SyncBadgeAppearance(
        color: BsSemanticColors.syncPending,
        icon: Icons.cloud_upload,
        label: l10n.pendingSync(pendingCount),
      ),
      SyncState.offline => SyncBadgeAppearance(
        color: BsSemanticColors.syncOffline,
        icon: Icons.cloud_off,
        label: l10n.offline,
      ),
      SyncState.incomplete => SyncBadgeAppearance(
        color: BsSemanticColors.syncPending,
        icon: Icons.cloud_sync_outlined,
        label: l10n.syncIncompleteContinue,
      ),
    };
  }
}

/// Persistent sync indicator — offline honesty (Design.md §5 of principles).
class SyncBadge extends StatelessWidget {
  const SyncBadge({
    super.key,
    required this.state,
    this.pendingCount = 0,
    this.iconOnly = false,
  });

  final SyncState state;
  final int pendingCount;
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appearance = SyncBadgeAppearance.from(
      l10n: l10n,
      state: state,
      pendingCount: pendingCount,
    );
    return Semantics(
      label: '${l10n.syncStatus}: ${appearance.label}',
      liveRegion: state == SyncState.incomplete,
      excludeSemantics: true,
      child: iconOnly
          ? Icon(appearance.icon, color: appearance.color)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(appearance.icon, size: 16, color: appearance.color),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    appearance.label,
                    style: TextStyle(color: appearance.color, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
    );
  }
}
