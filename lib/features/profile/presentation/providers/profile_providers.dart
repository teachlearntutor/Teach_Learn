import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kClassRemindersKey = 'pref_class_reminders';
const String _kAttendanceAlertsKey = 'pref_attendance_alerts';
const String _kLanguageKey = 'pref_app_language';

final notificationSettingsProvider =
    StateNotifierProvider<NotificationSettingsNotifier, Map<String, bool>>((ref) {
  return NotificationSettingsNotifier();
});

class NotificationSettingsNotifier extends StateNotifier<Map<String, bool>> {
  NotificationSettingsNotifier()
      : super({
          'classReminders': true,
          'attendanceAlerts': true,
        }) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = {
        'classReminders': prefs.getBool(_kClassRemindersKey) ?? true,
        'attendanceAlerts': prefs.getBool(_kAttendanceAlertsKey) ?? true,
      };
    } catch (_) {}
  }

  Future<void> toggleSetting(String key) async {
    final currentValue = state[key] ?? true;
    final newValue = !currentValue;
    state = {...state, key: newValue};

    try {
      final prefs = await SharedPreferences.getInstance();
      if (key == 'classReminders') {
        await prefs.setBool(_kClassRemindersKey, newValue);
      } else if (key == 'attendanceAlerts') {
        await prefs.setBool(_kAttendanceAlertsKey, newValue);
      }
    } catch (_) {}
  }
}

final appLanguageProvider = StateNotifierProvider<AppLanguageNotifier, String>((ref) {
  return AppLanguageNotifier();
});

class AppLanguageNotifier extends StateNotifier<String> {
  AppLanguageNotifier() : super('English') {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLang = prefs.getString(_kLanguageKey);
      if (savedLang != null) {
        state = savedLang;
      }
    } catch (_) {}
  }

  Future<void> setLanguage(String lang) async {
    state = lang;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLanguageKey, lang);
    } catch (_) {}
  }
}
