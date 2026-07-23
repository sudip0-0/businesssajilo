import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/layout/bs_breakpoints.dart';
import '../layout/web_bento_grid.dart';
import '../theme/web_palette.dart';
import '../theme/web_typography.dart';

/// Sectioned form card matching reference customer/bill layouts.
class WebFormCard extends StatelessWidget {
  const WebFormCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.children,
    this.footer,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<Widget> children;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return WebBentoTile(
      minHeight: 0,
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: WebPalette.navyWash,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: WebPalette.navy.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Icon(icon, size: 20, color: WebPalette.navy),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 19,
                        color: WebPalette.ink,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: WebPalette.inkSoft,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
          if (footer != null) ...[const SizedBox(height: 24), footer!],
        ],
      ),
    );
  }
}

class WebFormSectionLabel extends StatelessWidget {
  const WebFormSectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Text(label.toUpperCase(), style: WebTypography.eyebrow()),
          const SizedBox(width: 10),
          const Expanded(child: Divider(height: 1, color: WebPalette.hairline)),
        ],
      ),
    );
  }
}

class WebFormRow extends StatelessWidget {
  const WebFormRow({super.key, required this.children, this.gap = 16});

  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < BsBreakpoints.tablet;
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: gap),
            children[i],
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(width: gap),
          Expanded(child: children[i]),
        ],
      ],
    );
  }
}

class WebInfoTipCard extends StatelessWidget {
  const WebInfoTipCard({
    super.key,
    required this.message,
    required this.color,
    this.icon = PhosphorIconsRegular.info,
  });

  final String message;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: WebPalette.ink,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
