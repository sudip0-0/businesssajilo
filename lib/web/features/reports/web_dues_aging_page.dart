import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../features/reports/dues_aging_screen.dart';
import '../web_page_scaffold.dart';

class WebDuesAgingPage extends ConsumerWidget {
  const WebDuesAgingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return WebPageScaffold(
      title: l10n.duesAging,
      breadcrumbs: [l10n.reports, l10n.duesAging],
      body: const DuesAgingScreen(embedded: true),
    );
  }
}
