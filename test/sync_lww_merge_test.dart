import 'package:businesssajilo/data/sync/sync_merge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('remoteWins when remote updated_at is newer', () {
    final local = DateTime.utc(2026, 1, 1);
    final remote = DateTime.utc(2026, 6, 1);
    expect(remoteWins(local, remote), isTrue);
    expect(remoteWins(remote, local), isFalse);
  });

  test('pickNewerUpdatedAt returns latest timestamp', () {
    final local = DateTime.utc(2026, 3, 1);
    final remote = DateTime.utc(2026, 6, 1);
    expect(pickNewerUpdatedAt(local, remote), remote);
    expect(pickNewerUpdatedAt(remote, local), remote);
  });
}
