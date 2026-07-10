import 'package:flutter_test/flutter_test.dart';

import 'package:businesssajilo/data/sync/sync_models.dart';

void main() {
  group('SyncState', () {
    test('has expected values for badge mapping', () {
      expect(
        SyncState.values,
        containsAll([SyncState.synced, SyncState.pending, SyncState.offline]),
      );
    });
  });
}
