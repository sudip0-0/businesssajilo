import 'package:shared_preferences/shared_preferences.dart';

const onboardingTourPrefKey = 'onboarding_tour_v1_done';

const notifMuteDuesPrefKey = 'notif_mute_dues';
const notifMuteLowStockPrefKey = 'notif_mute_low_stock';

Future<bool> isOnboardingTourDone() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(onboardingTourPrefKey) ?? false;
}

Future<void> markOnboardingTourDone() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(onboardingTourPrefKey, true);
}

class NotificationMutePrefs {
  const NotificationMutePrefs({
    this.dues = true,
    this.lowStock = false,
  });

  final bool dues;
  final bool lowStock;

  List<String> get mutedTypes {
    return [
      if (dues) 'dues_reminder',
      if (lowStock) 'low_stock',
    ];
  }

  bool mutes(String type) => mutedTypes.contains(type);

  factory NotificationMutePrefs.fromMutedTypes(Iterable<String> muted) {
    final set = muted.toSet();
    return NotificationMutePrefs(
      dues: set.contains('dues_reminder'),
      lowStock: set.contains('low_stock'),
    );
  }

  /// Parses `members.notification_prefs`. Missing/invalid JSON keeps defaults.
  factory NotificationMutePrefs.fromNotificationPrefs(Object? raw) {
    if (raw == null) return const NotificationMutePrefs();
    if (raw is Map) {
      final muted = raw['muted'];
      if (muted is List) {
        return NotificationMutePrefs.fromMutedTypes(
          muted.map((e) => e.toString()),
        );
      }
    }
    return const NotificationMutePrefs();
  }

  static Future<NotificationMutePrefs> load() async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationMutePrefs(
      dues: prefs.getBool(notifMuteDuesPrefKey) ?? true,
      lowStock: prefs.getBool(notifMuteLowStockPrefKey) ?? false,
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(notifMuteDuesPrefKey, dues);
    await prefs.setBool(notifMuteLowStockPrefKey, lowStock);
  }

  NotificationMutePrefs copyWith({bool? dues, bool? lowStock}) {
    return NotificationMutePrefs(
      dues: dues ?? this.dues,
      lowStock: lowStock ?? this.lowStock,
    );
  }
}
