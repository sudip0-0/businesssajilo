import 'package:businesssajilo/core/ui/debounced_list_search.dart';
import 'package:businesssajilo/features/search/global_search_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'DebouncedListSearchController discards stale in-flight results',
    () async {
      var calls = 0;
      final started = <String>[];
      final controller = DebouncedListSearchController<String>(
        debounce: const Duration(milliseconds: 20),
        onChanged: () {},
        search: (query) async {
          calls += 1;
          started.add(query);
          await Future<void>.delayed(
            Duration(milliseconds: query == 'ab' ? 80 : 10),
          );
          return [query];
        },
      );

      controller.onQueryChanged('ab');
      await Future<void>.delayed(const Duration(milliseconds: 30));
      controller.onQueryChanged('abc');
      await Future<void>.delayed(const Duration(milliseconds: 120));

      expect(started, ['ab', 'abc']);
      expect(calls, 2);
      expect(controller.results, ['abc']);
      expect(controller.phase, ListSearchPhase.data);
      controller.dispose();
    },
  );

  test('global search min chars is two', () {
    expect(kGlobalSearchMinChars, 2);
    expect(kGlobalSearchDebounce, const Duration(milliseconds: 300));
  });
}
