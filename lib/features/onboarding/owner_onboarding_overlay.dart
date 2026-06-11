import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import 'onboarding_prefs.dart';

class OwnerOnboardingOverlay extends StatefulWidget {
  const OwnerOnboardingOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<OwnerOnboardingOverlay> createState() => _OwnerOnboardingOverlayState();
}

class _OwnerOnboardingOverlayState extends State<OwnerOnboardingOverlay> {
  bool _visible = false;
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
    await setOnboardingComplete();
    if (mounted) setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_visible) ...[
          ModalBarrier(
            dismissible: false,
            color: Colors.black54,
          ),
          Center(
            child: _OnboardingCard(
              step: _step,
              onNext: () {
                if (_step >= 3) {
                  _finish();
                } else {
                  setState(() => _step++);
                }
              },
              onSkip: _finish,
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
    required this.onNext,
    required this.onSkip,
  });

  final int step;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final steps = [
      (Icons.dashboard, l10n.onboardingWelcome, l10n.onboardingKpis),
      (Icons.inventory_2, l10n.inventory, l10n.onboardingProducts),
      (Icons.storefront, l10n.customers, l10n.onboardingCustomers),
      (Icons.receipt_long, l10n.billing, l10n.onboardingBills),
    ];
    final (icon, title, body) = steps[step];

    return Card(
      margin: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48),
              const SizedBox(height: 16),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Text(body, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: onSkip, child: Text(l10n.onboardingSkip)),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: onNext,
                    child: Text(
                      step >= 3 ? l10n.onboardingDone : l10n.onboardingNext,
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
