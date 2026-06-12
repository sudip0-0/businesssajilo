import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class WebSkeleton extends StatelessWidget {
  const WebSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 8,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 1200.ms,
          color: scheme.surfaceContainerHigh.withValues(alpha: 0.6),
        );
  }
}

class WebListSkeleton extends StatelessWidget {
  const WebListSkeleton({super.key, this.itemCount = 8});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) => Row(
        children: [
          WebSkeleton(width: 40, height: 40, borderRadius: 10)
              .animate()
              .fadeIn(delay: (i * 60).ms),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WebSkeleton(height: 14)
                    .animate()
                    .fadeIn(delay: (i * 60 + 20).ms),
                const SizedBox(height: 8),
                WebSkeleton(width: 120, height: 12)
                    .animate()
                    .fadeIn(delay: (i * 60 + 40).ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
