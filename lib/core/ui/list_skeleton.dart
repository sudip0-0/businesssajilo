import 'package:flutter/material.dart';

/// Placeholder skeleton rows for list loading states.
class ListSkeleton extends StatefulWidget {
  const ListSkeleton({super.key, this.rowCount = 6});

  final int rowCount;

  @override
  State<ListSkeleton> createState() => _ListSkeletonState();
}

class _ListSkeletonState extends State<ListSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: widget.rowCount,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = ((_controller.value + index * 0.1) % 1.0);
            final opacity = 0.35 + (t < 0.5 ? t : 1 - t) * 0.45;
            return Opacity(opacity: opacity, child: child);
          },
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            title: Container(
              height: 14,
              width: double.infinity,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                height: 12,
                width: 120,
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
