import 'package:shared_preferences/shared_preferences.dart';

const onboardingTourPrefKey = 'onboarding_tour_v1_done';

const notifMuteChatPrefKey = 'notif_mute_chat';
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
    this.chat = false,
    this.dues = true,
    this.lowStock = false,
  });

  final bool chat;
  final bool dues;
  final bool lowStock;

  List<String> get mutedTypes {
    return [
      if (chat) 'chat_message',
      if (dues) 'dues_reminder',
      if (lowStock) 'low_stock',
    ];
  }

  static Future<NotificationMutePrefs> load() async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationMutePrefs(
      chat: prefs.getBool(notifMuteChatPrefKey) ?? false,
      dues: prefs.getBool(notifMuteDuesPrefKey) ?? true,
      lowStock: prefs.getBool(notifMuteLowStockPrefKey) ?? false,
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(notifMuteChatPrefKey, chat);
    await prefs.setBool(notifMuteDuesPrefKey, dues);
    await prefs.setBool(notifMuteLowStockPrefKey, lowStock);
  }

  NotificationMutePrefs copyWith({bool? chat, bool? dues, bool? lowStock}) {
    return NotificationMutePrefs(
      chat: chat ?? this.chat,
      dues: dues ?? this.dues,
      lowStock: lowStock ?? this.lowStock,
    );
  }
}
