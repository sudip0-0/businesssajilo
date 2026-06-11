import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeModeKey = 'app_theme_mode';

Future<ThemeMode?> loadSavedThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  final name = prefs.getString(_themeModeKey);
  if (name == null) return null;
  return ThemeMode.values
      .where((m) => m.name == name)
      .firstOrNull;
}

Future<void> saveThemeMode(ThemeMode mode) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_themeModeKey, mode.name);
}
