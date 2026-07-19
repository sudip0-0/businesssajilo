import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/web_palette.dart';
import '../theme/web_typography.dart';

class WebEmptyState extends StatelessWidget {
  const WebEmptyState({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.icon = PhosphorIconsRegular.tray,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: WebPalette.brassWash,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: WebPalette.brass.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Icon(icon, size: 28, color: WebPalette.brassDeep),
                )
                .animate()
                .fadeIn(duration: 380.ms)
                .scale(
                  begin: const Offset(0.85, 0.85),
                  duration: 380.ms,
                  curve: Curves.easeOutBack,
                ),
            const SizedBox(height: 18),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: WebTypography.serif(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                  color: WebPalette.inkSoft,
                ),
              ),
            ).animate().fadeIn(duration: 380.ms, delay: 90.ms),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 22),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ).animate().fadeIn(duration: 380.ms, delay: 170.ms),
            ],
          ],
        ),
      ),
    );
  }
}
