import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../web/theme/web_theme.dart';
import 'demo_data_seeder.dart';
import 'onboarding_prefs.dart';

const _stepCount = 6;

class OwnerOnboardingOverlay extends ConsumerStatefulWidget {
  const OwnerOnboardingOverlay({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<OwnerOnboardingOverlay> createState() =>
      _OwnerOnboardingOverlayState();
}

class _OwnerOnboardingOverlayState
    extends ConsumerState<OwnerOnboardingOverlay> {
  bool _visible = false;
  bool _seeding = false;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final done = await isOnboardingComplete();
    if (!done && mounted) setState(() => _visible = true);
  }

  Future<void> _finish() async {
    if (mounted) setState(() => _visible = false);
    try {
      await setOnboardingComplete();
    } catch (_) {
      // Dismiss the overlay even if persistence fails so the UI stays usable.
    }
  }

  Future<void> _seedAndFinish() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _seeding = true);
    try {
      final result = await DemoDataSeeder(ref).seed();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            result == DemoSeedResult.loaded
                ? l10n.demoDataLoaded
                : l10n.demoDataSkipped,
          ),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.actionFailed)));
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
    await _finish();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_visible) ...[
          Positioned.fill(
            child: ModalBarrier(
              dismissible: false,
              color: Colors.black54,
            ),
          ),
          Center(
            child: Theme(
              data: WebTheme.light(),
              child: _OnboardingCard(
                step: _step,
                seeding: _seeding,
                onNext: () {
                  if (_step >= _stepCount - 1) {
                    _finish();
                  } else {
                    setState(() => _step++);
                  }
                },
                onSkip: _seeding ? null : _finish,
                onLoadSampleData: _seeding ? null : _seedAndFinish,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _OnboardingCard extends StatelessWidget {
  const _OnboardingCard({
    required this.step,
    required this.seeding,
    required this.onNext,
    required this.onSkip,
    required this.onLoadSampleData,
  });

  final int step;
  final bool seeding;
  final VoidCallback onNext;
  final VoidCallback? onSkip;
  final VoidCallback? onLoadSampleData;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final steps = [
      (Icons.dashboard, l10n.onboardingWelcome, l10n.onboardingKpis),
      (Icons.inventory_2, l10n.inventory, l10n.onboardingProducts),
      (Icons.storefront, l10n.customers, l10n.onboardingCustomers),
      (Icons.receipt_long, l10n.billing, l10n.onboardingBills),
      (Icons.shopping_cart, l10n.orders, l10n.onboardingOrders),
      (Icons.assessment, l10n.reports, l10n.onboardingReports),
    ];
    final (icon, title, body) = steps[step];
    final isLast = step >= steps.length - 1;

    return Material(
      color: Colors.white,
      elevation: 8,
      borderRadius: BorderRadius.circular(BsRadii.lg),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: BsColors.primary),
              const SizedBox(height: 16),
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: BsColors.textCharcoal,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                body,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: BsColors.outline,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < steps.length; i++)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == step
                            ? BsColors.primary
                            : BsColors.outlineVariant,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (isLast) ...[
                FilledButton.tonalIcon(
                  onPressed: onLoadSampleData,
                  icon: seeding
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.dataset_outlined),
                  label: Text(l10n.loadDemoData),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onSkip,
                    child: Text(l10n.onboardingSkip),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: seeding ? null : onNext,
                    child: Text(
                      isLast ? l10n.onboardingDone : l10n.onboardingNext,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
