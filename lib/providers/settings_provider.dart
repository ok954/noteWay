import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/fonts.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in ProviderScope');
});

// ========== 主题模式 ==========

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const String _key = 'theme_mode';

  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final value = prefs.getString(_key);
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = ref.read(sharedPreferencesProvider);
    String value;
    switch (mode) {
      case ThemeMode.light:
        value = 'light';
        break;
      case ThemeMode.dark:
        value = 'dark';
        break;
      case ThemeMode.system:
        value = 'system';
        break;
    }
    await prefs.setString(_key, value);
    state = mode;
  }
}

// ========== 字体设置 ==========

final fontIdProvider = NotifierProvider<FontNotifier, String>(FontNotifier.new);

class FontNotifier extends Notifier<String> {
  static const String _key = 'font_id';

  @override
  String build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final savedId = prefs.getString(_key);
    if (savedId != null && findAppFontById(savedId) != null) {
      return savedId;
    }
    return defaultAppFont.id;
  }

  Future<void> setFont(String fontId) async {
    if (findAppFontById(fontId) == null) return;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, fontId);
    state = fontId;
  }

  /// 当前选中的字体对象
  AppFont get currentFont => findAppFontById(state) ?? defaultAppFont;
}

// ========== 组合提供商 ==========

/// 当前字体信息
final currentFontProvider = Provider<AppFont>((ref) {
  final fontId = ref.watch(fontIdProvider);
  return findAppFontById(fontId) ?? defaultAppFont;
});
