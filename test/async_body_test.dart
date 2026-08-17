import 'dart:async';

import 'package:businesssajilo/core/ui/async_body.dart';
import 'package:businesssajilo/core/ui/list_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AsyncBody shows skeleton while loading', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AsyncBody<List<int>>(
            value: const AsyncLoading(),
            data: (d) => Text('${d.length}'),
          ),
        ),
      ),
    );
    expect(find.byType(ListSkeleton), findsOneWidget);
  });

  testWidgets('AsyncBody shows data when ready', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AsyncBody<List<int>>(
            value: const AsyncData([1, 2]),
            data: (d) => Text('count ${d.length}'),
          ),
        ),
      ),
    );
    expect(find.text('count 2'), findsOneWidget);
  });

  testWidgets('AsyncBody keeps data while reloading', (tester) async {
    final completer = Completer<List<int>>();
    var calls = 0;
    final provider = FutureProvider<List<int>>((ref) {
      calls += 1;
      if (calls == 1) return Future.value([1, 2]);
      return completer.future;
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                return AsyncBody<List<int>>(
                  value: ref.watch(provider),
                  data: (d) => Text('count ${d.length}'),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('count 2'), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(AsyncBody<List<int>>)),
    );
    container.invalidate(provider);
    await tester.pump();

    expect(find.text('count 2'), findsOneWidget);
    expect(find.byType(ListSkeleton), findsNothing);

    completer.complete([1, 2, 3]);
    await tester.pumpAndSettle();
    expect(find.text('count 3'), findsOneWidget);
  });
}
