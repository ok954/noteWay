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

// ========== 字体大小 ==========

final fontSizeProvider = NotifierProvider<FontSizeNotifier, double>(FontSizeNotifier.new);

class FontSizeNotifier extends Notifier<double> {
  static const String _key = 'font_size_multiplier';

  @override
  double build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getDouble(_key) ?? 1.0;
  }

  Future<void> setFontSize(double multiplier) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setDouble(_key, multiplier);
    state = multiplier;
  }
}

// ========== 提醒音效 ==========

final reminderSoundProvider = NotifierProvider<ReminderSoundNotifier, ReminderSoundSettings>(ReminderSoundNotifier.new);

class ReminderSoundSettings {
  final bool enabled;
  final String soundType; // 'default', 'gentle', 'bell', 'none'

  const ReminderSoundSettings({this.enabled = true, this.soundType = 'default'});

  String get label {
    switch (soundType) {
      case 'gentle': return '柔和';
      case 'bell': return '铃声';
      case 'none': return '静音';
      default: return '默认';
    }
  }
}

class ReminderSoundNotifier extends Notifier<ReminderSoundSettings> {
  static const String _enabledKey = 'reminder_sound_enabled';
  static const String _typeKey = 'reminder_sound_type';

  @override
  ReminderSoundSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return ReminderSoundSettings(
      enabled: prefs.getBool(_enabledKey) ?? true,
      soundType: prefs.getString(_typeKey) ?? 'default',
    );
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_enabledKey, enabled);
    state = ReminderSoundSettings(enabled: enabled, soundType: state.soundType);
  }

  Future<void> setSoundType(String type) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_typeKey, type);
    state = ReminderSoundSettings(enabled: state.enabled, soundType: type);
  }
}

// ========== 应用锁 ==========

final appLockProvider = NotifierProvider<AppLockNotifier, AppLockSettings>(AppLockNotifier.new);

class AppLockSettings {
  final bool enabled;
  final String? pinHash;

  const AppLockSettings({this.enabled = false, this.pinHash});

  bool get hasPin => pinHash != null && pinHash!.isNotEmpty;
}

class AppLockNotifier extends Notifier<AppLockSettings> {
  static const String _enabledKey = 'app_lock_enabled';
  static const String _pinKey = 'app_lock_pin';

  @override
  AppLockSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return AppLockSettings(
      enabled: prefs.getBool(_enabledKey) ?? false,
      pinHash: prefs.getString(_pinKey),
    );
  }

  Future<void> setPin(String pin) async {
    final prefs = ref.read(sharedPreferencesProvider);
    // Simple hash for local PIN (not cryptographic - just obfuscation)
    final hash = pin.split('').map((c) => c.codeUnitAt(0)).reduce((a, b) => a * 31 + b).toString();
    await prefs.setString(_pinKey, hash);
    await prefs.setBool(_enabledKey, true);
    state = AppLockSettings(enabled: true, pinHash: hash);
  }

  bool verifyPin(String pin) {
    final hash = pin.split('').map((c) => c.codeUnitAt(0)).reduce((a, b) => a * 31 + b).toString();
    return hash == state.pinHash;
  }

  Future<void> disable() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(_pinKey);
    await prefs.setBool(_enabledKey, false);
    state = const AppLockSettings(enabled: false, pinHash: null);
  }
}
