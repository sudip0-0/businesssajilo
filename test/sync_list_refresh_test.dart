import 'dart:async';

import 'package:businesssajilo/data/sync/sync_models.dart';
import 'package:businesssajilo/data/sync/sync_providers.dart';
import 'package:businesssajilo/features/billing/providers.dart';
import 'package:businesssajilo/features/customers/providers.dart';
import 'package:businesssajilo/features/inventory/providers.dart';
import 'package:businesssajilo/features/sync/sync_list_refresh.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('sync queue drain and pull success bump list revisions', (
    tester,
  ) async {
    final controller = StreamController<SyncStatus>();
    addTearDown(controller.close);

    final container = ProviderContainer(
      overrides: [syncStatusProvider.overrideWith((ref) => controller.stream)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const SizedBox()),
    );

    container.read(syncQueueListRefreshProvider);
    container.listen(syncStatusProvider, (_, _) {});
    controller.add(const SyncStatus(state: SyncState.synced));
    await tester.pump();

    expect(container.read(billingRevisionProvider), 0);
    expect(container.read(inventoryRevisionProvider), 0);
    expect(container.read(customersRevisionProvider), 0);

    controller.add(const SyncStatus(state: SyncState.pending, pendingCount: 1));
    await tester.pump();
    expect(container.read(billingRevisionProvider), 1);
    expect(container.read(inventoryRevisionProvider), 1);
    expect(container.read(customersRevisionProvider), 1);

    controller.add(const SyncStatus(state: SyncState.synced));
    await tester.pump();
    expect(container.read(billingRevisionProvider), 2);

    controller.add(
      SyncStatus(
        state: SyncState.synced,
        lastSuccessAt: DateTime.utc(2026, 8, 17),
      ),
    );
    await tester.pump();
    expect(container.read(billingRevisionProvider), 3);
    expect(container.read(inventoryRevisionProvider), 3);
    expect(container.read(customersRevisionProvider), 3);
  });
}
