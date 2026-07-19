import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/l10n/app_localizations.dart';
import '../theme/web_palette.dart';
import '../theme/web_typography.dart';
import '../ui/web_paper.dart';

/// The ink-navy brand panel shared by the web auth pages — deep gradient,
/// ledger rules, a brass-accented wordmark and a faded रू watermark.
class WebAuthBrandPanel extends StatelessWidget {
  const WebAuthBrandPanel({
    super.key,
    required this.headline,
    required this.subhead,
    this.showFeatures = true,
  });

  final String headline;
  final String subhead;
  final bool showFeatures;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: const BoxDecoration(gradient: WebPalette.brandGradient),
      child: Stack(
        children: [
          // Ledger rules — the account-book texture.
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: LedgerLinesPainter()),
            ),
          ),
          // Oversized रू watermark — quiet Nepali identity.
          Positioned(
            right: -30,
            bottom: -60,
            child: IgnorePointer(
              child: Text(
                'रू',
                style: TextStyle(
                  fontFamily: 'Noto Sans Devanagari',
                  fontSize: 300,
                  fontWeight: FontWeight.w400,
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.045),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(56, 48, 56, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand row.
                Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: WebPalette.brass.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: WebPalette.brassBright.withValues(
                                alpha: 0.45,
                              ),
                            ),
                          ),
                          child: const Icon(
                            PhosphorIconsRegular.storefront,
                            color: WebPalette.brassBright,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          l10n.appTitle,
                          style: WebTypography.serif(
                            fontSize: 21,
                            fontWeight: FontWeight.w600,
                            color: WebPalette.railTextBright,
                          ),
                        ),
                      ],
                    )
                    .animate()
                    .fadeIn(duration: 420.ms)
                    .slideY(begin: 0.06, end: 0, duration: 420.ms),
                const Spacer(),
                // Headline block.
                Text(
                      headline,
                      style: WebTypography.serif(
                        fontSize: 44,
                        fontWeight: FontWeight.w600,
                        height: 1.12,
                        letterSpacing: -0.4,
                        color: Colors.white,
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 480.ms, delay: 120.ms)
                    .slideY(begin: 0.08, end: 0, duration: 480.ms),
                const SizedBox(height: 18),
                Container(
                  width: 56,
                  height: 3,
                  decoration: BoxDecoration(
                    color: WebPalette.brassBright,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ).animate().fadeIn(duration: 420.ms, delay: 240.ms),
                const SizedBox(height: 18),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Text(
                        subhead,
                        style: WebTypography.serif(
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                          height: 1.55,
                          color: Colors.white.withValues(alpha: 0.78),
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 480.ms, delay: 260.ms)
                      .slideY(begin: 0.08, end: 0, duration: 480.ms),
                ),
                if (showFeatures) ...[
                  const SizedBox(height: 44),
                  _FeatureRow(
                    icon: PhosphorIconsRegular.receipt,
                    text: l10n.billing,
                    delay: 360.ms,
                  ),
                  const SizedBox(height: 14),
                  _FeatureRow(
                    icon: PhosphorIconsRegular.package,
                    text: l10n.inventory,
                    delay: 440.ms,
                  ),
                  const SizedBox(height: 14),
                  _FeatureRow(
                    icon: PhosphorIconsRegular.chartBar,
                    text: l10n.reports,
                    delay: 520.ms,
                  ),
                ],
                const Spacer(),
                // Footer microline.
                Text(
                  '${l10n.inventory} • ${l10n.billing} • ${l10n.reports}'
                      .toUpperCase(),
                  style: WebTypography.eyebrow(
                    color: Colors.white.withValues(alpha: 0.4),
                  ).copyWith(fontSize: 10, letterSpacing: 1.8),
                ).animate().fadeIn(duration: 480.ms, delay: 600.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.text,
    required this.delay,
  });

  final IconData icon;
  final String text;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: WebPalette.brass.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: WebPalette.brassBright.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(icon, size: 15, color: WebPalette.brassBright),
            ),
            const SizedBox(width: 13),
            Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.88),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        )
        .animate()
        .fadeIn(duration: 420.ms, delay: delay)
        .slideX(begin: -0.04, end: 0, duration: 420.ms, delay: delay);
  }
}
