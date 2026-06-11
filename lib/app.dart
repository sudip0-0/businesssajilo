import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/env.dart';
import 'core/l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/ui/sync_badge.dart';

/// App locale; persisted per user in later phases.
final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() => const Locale('en');

  void toggle() {
    state = state.languageCode == 'en'
        ? const Locale('ne')
        : const Locale('en');
  }
}

class BusinessSajiloApp extends ConsumerWidget {
  const BusinessSajiloApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return MaterialApp(
      title: 'BusinessSajilo',
      theme: AppTheme.light(),
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ne')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      home: const LaunchScreen(),
    );
  }
}

/// Temporary launch screen until auth + role routing land (Phase 1).
class LaunchScreen extends ConsumerWidget {
  const LaunchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Center(child: SyncBadge(state: SyncState.offline)),
          ),
          IconButton(
            tooltip: l10n.language,
            icon: const Icon(Icons.translate),
            onPressed: () => ref.read(localeProvider.notifier).toggle(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storefront, size: 64, color: BsColors.primary),
            const SizedBox(height: 16),
            Text(
              l10n.appTitle,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: BsColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(l10n.tagline, style: Theme.of(context).textTheme.bodyLarge),
            if (!Env.isConfigured) ...[
              const SizedBox(height: 24),
              Text(
                'Supabase not configured — pass --dart-define '
                'SUPABASE_URL and SUPABASE_ANON_KEY.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: BsColors.danger),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
