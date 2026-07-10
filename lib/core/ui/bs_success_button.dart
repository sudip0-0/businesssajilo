import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Green success action button per Design.md (Add, Confirm, Save).
class BsSuccessButton extends StatelessWidget {
  const BsSuccessButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.outlined = false,
    this.loading = false,
  });

  final VoidCallback? onPressed;
  final String label;
  final Widget? icon;
  final bool outlined;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = loading ? null : onPressed;
    final child = loading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : icon != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [icon!, const SizedBox(width: 8), Text(label)],
          )
        : Text(label);

    if (outlined) {
      return OutlinedButton(
        onPressed: effectiveOnPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: BsColors.secondary,
          side: const BorderSide(color: BsColors.secondary),
        ),
        child: child,
      );
    }

    return FilledButton(
      onPressed: effectiveOnPressed,
      style: FilledButton.styleFrom(
        backgroundColor: BsColors.secondary,
        foregroundColor: BsColors.onSecondary,
      ),
      child: child,
    );
  }
}
