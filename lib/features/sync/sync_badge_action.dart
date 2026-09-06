import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/layout/bs_touch_targets.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/ui/sync_badge.dart';
import '../../data/sync/sync_providers.dart';
import 'pending_sync_screen.dart';

class SyncBadgeAction extends ConsumerWidget {
  const SyncBadgeAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final statusAsync = ref.watch(syncStatusProvider);
    final recoveryNotice =
        ref.watch(legacyRecoveryNoticeProvider).value != null;
    return statusAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) =>
          _iconButton(context, l10n: l10n, state: SyncState.offline),
      data: (status) {
        if (status.state == SyncState.synced && !recoveryNotice) {
          return const SizedBox.shrink();
        }
        return _iconButton(
          context,
          l10n: l10n,
          state: status.state,
          pendingCount: status.pendingCount,
          recoveryNotice: recoveryNotice,
        );
      },
    );
  }

  Widget _iconButton(
    BuildContext context, {
    required AppLocalizations l10n,
    required SyncState state,
    int pendingCount = 0,
    bool recoveryNotice = false,
  }) {
    final appearance = SyncBadgeAppearance.from(
      l10n: l10n,
      state: state,
      pendingCount: pendingCount,
    );
    return BsTouchTargets.ensureMin(
      context: context,
      child: IconButton(
        tooltip: recoveryNotice ? l10n.legacyRecoveryTitle : appearance.label,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PendingSyncScreen()),
          );
        },
        icon: recoveryNotice && state == SyncState.synced
            ? const Icon(Icons.history)
            : SyncBadge(
                state: state,
                pendingCount: pendingCount,
                iconOnly: true,
              ),
      ),
    );
  }
}
