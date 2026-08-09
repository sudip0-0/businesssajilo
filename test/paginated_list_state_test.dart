import 'dart:async';

import 'package:businesssajilo/core/config/pagination.dart';
import 'package:businesssajilo/core/ui/paginated_list_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loadAll waits for in-flight loadMore before continuing', () async {
    final gate = Completer<void>();
    var calls = 0;
    final pager = PaginatedListState<int>(
      loadPage: (offset, limit) async {
        calls++;
        if (calls == 1) await gate.future;
        if (offset >= kListPageSize) {
          return <int>[offset]; // short final page ends pagination
        }
        return List.generate(limit, (i) => offset + i);
      },
    );

    // Start a first page that stays in-flight.
    final first = pager.loadMore();
    expect(pager.loading, isTrue);

    // loadAll used to exit immediately while loading was true.
    final loadAll = pager.loadAll();
    gate.complete();
    await first;
    await loadAll;

    expect(pager.hasMore, isFalse);
    expect(pager.items.length, kListPageSize + 1);
    expect(calls, 2);
  });
}
