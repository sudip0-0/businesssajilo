import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/empty_state.dart';
import '../../data/sync/sync_providers.dart';

class PendingSyncScreen extends ConsumerWidget {
  const PendingSyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final bundle = ref.watch(syncBundleProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.pendingSyncItems)),
      body: bundle == null
          ? EmptyState(
              icon: Icons.cloud_done,
              message: l10n.synced,
            )
          : FutureBuilder(
              future: bundle.db.pendingQueue(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snapshot.data!;
                if (items.isEmpty) {
                  return EmptyState(
                    icon: Icons.cloud_done,
                    message: l10n.synced,
                    actionLabel: l10n.syncNow,
                    onAction: () => bundle.sync.syncNow(),
                  );
                }
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () async {
                            await bundle.sync.syncNow();
                            ref.invalidate(syncStatusProvider);
                            if (context.mounted) {
                              (context as Element).markNeedsBuild();
                            }
                          },
                          icon: const Icon(Icons.sync),
                          label: Text(l10n.syncNow),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return ListTile(
                            leading: Icon(
                              item.status == 'failed'
                                  ? Icons.error_outline
                                  : Icons.cloud_upload_outlined,
                              color: item.status == 'failed'
                                  ? BsColors.danger
                                  : BsColors.accent,
                            ),
                            title: Text('${item.entityType} · ${item.entityId}'),
                            subtitle: item.lastError == null
                                ? Text(item.status)
                                : Text(
                                    '${l10n.syncFailed}: ${item.lastError}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                            trailing: item.status == 'failed'
                                ? TextButton(
                                    onPressed: () async {
                                      await bundle.sync.syncNow();
                                      ref.invalidate(syncStatusProvider);
                                    },
                                    child: Text(l10n.retrySync),
                                  )
                                : null,
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
