import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kThemeModeKey = 'app_theme_mode';

/// Riverpod provider for ThemeMode persisted via SharedPreferences.
final themeModeNotifierProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light) {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_kThemeModeKey);
      if (savedTheme != null) {
        if (savedTheme == 'dark') {
          state = ThemeMode.dark;
        } else if (savedTheme == 'light') {
          state = ThemeMode.light;
        } else if (savedTheme == 'system') {
          state = ThemeMode.system;
        }
      }
    } catch (_) {
      // Fallback to default ThemeMode.light if shared_preferences read fails
    }
  }

  Future<void> toggleThemeMode() async {
    final nextTheme = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = nextTheme;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kThemeModeKey, nextTheme == ThemeMode.dark ? 'dark' : 'light');
    } catch (_) {
      // Async write error handling
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      final String modeString = mode == ThemeMode.dark
          ? 'dark'
          : mode == ThemeMode.light
              ? 'light'
              : 'system';
      await prefs.setString(_kThemeModeKey, modeString);
    } catch (_) {
      // Async write error handling
    }
  }
}
