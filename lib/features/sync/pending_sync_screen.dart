import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/empty_state.dart';
import '../../core/utils/sync_labels.dart';
import '../../data/local/app_database.dart';
import '../../data/sync/sync_providers.dart';

class PendingSyncScreen extends ConsumerWidget {
  const PendingSyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final bundle = ref.watch(syncBundleProvider);
    final queueAsync = ref.watch(syncQueueProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.pendingSyncItems)),
      body: bundle == null
          ? EmptyState(
              icon: Icons.cloud_done,
              message: l10n.synced,
            )
          : queueAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => EmptyState(
                icon: Icons.error_outline,
                message: l10n.somethingWentWrong,
                actionLabel: l10n.tryAgain,
                onAction: () => ref.invalidate(syncQueueProvider),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return EmptyState(
                    icon: Icons.cloud_done,
                    message: l10n.synced,
                    actionLabel: l10n.syncNow,
                    onAction: () => bundle.sync.syncNow(),
                  );
                }
                final failedCount =
                    items.where((i) => i.status == 'failed').length;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FilledButton.icon(
                            onPressed: () async {
                              await bundle.sync.syncNow();
                              ref.invalidate(syncStatusProvider);
                            },
                            icon: const Icon(Icons.sync),
                            label: Text(l10n.syncNow),
                          ),
                          if (failedCount > 0) ...[
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () async {
                                await bundle.sync.retryFailed();
                                ref.invalidate(syncStatusProvider);
                              },
                              icon: const Icon(Icons.restart_alt,
                                  color: BsColors.danger),
                              label: Text(
                                '${l10n.retrySync} — '
                                '${l10n.failedSyncItems(failedCount)}',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) => _QueueTile(
                          item: items[index],
                          onRetry: () async {
                            await bundle.sync.retryFailed();
                            ref.invalidate(syncStatusProvider);
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _QueueTile extends StatelessWidget {
  const _QueueTile({required this.item, required this.onRetry});

  final SyncQueueData item;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final failed = item.status == 'failed';
    return ListTile(
      leading: Icon(
        failed ? Icons.error_outline : Icons.cloud_upload_outlined,
        color: failed ? BsColors.danger : BsColors.accent,
      ),
      tileColor: failed ? BsColors.danger.withValues(alpha: 0.06) : null,
      title: Text(
        '${syncEntityLabel(l10n, item.entityType)} · ${item.entityId}',
      ),
      subtitle: item.lastError == null
          ? Text(syncStatusLabel(l10n, item.status))
          : Text(
              '${l10n.syncFailed}: ${l10n.syncErrorGeneric}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: failed
          ? TextButton(
              onPressed: onRetry,
              child: Text(l10n.retrySync),
            )
          : null,
    );
  }
}
