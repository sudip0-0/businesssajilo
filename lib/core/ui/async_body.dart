import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'error_state.dart';
import 'list_skeleton.dart';

/// Wraps [AsyncValue]: skeleton on loading, [ErrorState] on error, child on data.
class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
    this.skeletonRows = 6,
    this.useSkeleton = true,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;
  final int skeletonRows;
  final bool useSkeleton;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => useSkeleton
          ? ListSkeleton(rowCount: skeletonRows)
          : const Center(child: CircularProgressIndicator()),
      error: (_, _) => ErrorState(onRetry: onRetry),
      data: data,
    );
  }
}
