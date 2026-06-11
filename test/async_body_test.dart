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
}
