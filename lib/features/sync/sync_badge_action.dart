import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ui/sync_badge.dart';
import '../../data/sync/sync_providers.dart';
import 'pending_sync_screen.dart';

class SyncBadgeAction extends ConsumerWidget {
  const SyncBadgeAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(syncStatusProvider);
    return statusAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: SyncBadge(state: SyncState.synced),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (status) => TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PendingSyncScreen()),
          );
        },
        child: SyncBadge(
          state: status.state,
          pendingCount: status.pendingCount,
        ),
      ),
    );
  }
}
