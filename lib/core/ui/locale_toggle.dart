import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app.dart';
import '../l10n/app_localizations.dart';

/// Language EN/NE toggle — full-width on forms, compact in app bars.
class LocaleToggle extends ConsumerWidget {
  const LocaleToggle({
    super.key,
    this.compact = false,
    this.fullWidth = false,
    this.alignment = Alignment.center,
  });

  final bool compact;
  final bool fullWidth;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);

    final enLabel = compact ? 'EN' : l10n.english;
    final neLabel = compact ? 'NE' : l10n.nepali;

    final button = SegmentedButton<String>(
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 20,
          vertical: compact ? 8 : 12,
        ),
        minimumSize: Size(compact ? 48 : 72, compact ? 32 : 40),
      ),
      segments: [
        ButtonSegment(
          value: 'en',
          label: Text(enLabel, maxLines: 1, softWrap: false),
        ),
        ButtonSegment(
          value: 'ne',
          label: Text(neLabel, maxLines: 1, softWrap: false),
        ),
      ],
      selected: {locale.languageCode},
      onSelectionChanged: (selected) => ref
          .read(localeProvider.notifier)
          .setLocale(Locale(selected.first)),
    );

    Widget child = button;
    if (fullWidth) {
      child = SizedBox(width: double.infinity, child: button);
    }

    return Align(alignment: alignment, child: child);
  }
}
