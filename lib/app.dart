import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n/app_localizations.dart';
import 'core/notifications/push_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'web/navigation/web_notification_navigation.dart';
import 'web/theme/web_theme.dart';
import 'core/utils/locale_prefs.dart';
import 'core/utils/theme_prefs.dart';
import 'domain/models/notification_item.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/notifications/notification_navigation.dart';

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// App locale; persisted per device via SharedPreferences.
final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    _loadSaved();
    return const Locale('en');
  }

  Future<void> _loadSaved() async {
    final saved = await loadSavedLocale();
    if (saved != null) state = saved;
  }

  void setLocale(Locale locale) {
    state = locale;
    saveLocale(locale);
  }

  void toggle() {
    setLocale(
      state.languageCode == 'en' ? const Locale('ne') : const Locale('en'),
    );
  }
}

/// App theme mode; persisted per device via SharedPreferences.
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _loadSaved();
    // Web admin UI is designed for light mode; system dark caused unreadable forms.
    return kIsWeb ? ThemeMode.light : ThemeMode.system;
  }

  Future<void> _loadSaved() async {
    final saved = await loadSavedThemeMode();
    if (saved != null) state = saved;
  }

  void setMode(ThemeMode mode) {
    state = mode;
    saveThemeMode(mode);
  }
}

class BusinessSajiloApp extends ConsumerWidget {
  const BusinessSajiloApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);

    // Wire push notification taps and foreground banners into the app.
    PushService.onNotificationTap = (data) {
      final navContext = rootNavigatorKey.currentContext;
      if (navContext == null) return;
      final role = ref.read(authProvider).value?.member?.role;
      final item = NotificationItem(
        id: data['notification_id'] as String? ?? '',
        businessId: data['business_id'] as String? ?? '',
        recipientMemberId: data['recipient_member_id'] as String? ?? '',
        type: data['type'] as String? ?? '',
        payload: data,
      );
      if (kIsWeb) {
        openWebNotificationTarget(navContext, item, role: role);
      } else {
        openNotificationTarget(navContext, item, role: role);
      }
    };
    PushService.onForegroundMessage = (message) {
      final title = message.notification?.title ?? message.data['title'];
      final body = message.notification?.body ?? message.data['body'];
      final text = [title, body].whereType<String>().join(' — ');
      if (text.isEmpty) return;
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(text)),
      );
    };

    return MaterialApp.router(
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: 'BusinessSajilo',
      theme: kIsWeb ? WebTheme.light() : AppTheme.light(),
      darkTheme: kIsWeb ? WebTheme.dark() : AppTheme.dark(),
      themeMode: themeMode,
      locale: locale,
      builder: (context, child) {
        // Respect user font scaling but clamp to keep layouts usable.
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(
              minScaleFactor: 1.0,
              maxScaleFactor: 1.3,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      supportedLocales: const [Locale('en'), Locale('ne')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
