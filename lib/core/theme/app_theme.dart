import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../constants/fonts.dart';

class AppTheme {
  AppTheme._();

  /// 构建浅色主题
  static ThemeData lightTheme([String? fontId]) {
    final font = fontId != null ? (findAppFontById(fontId) ?? defaultAppFont) : defaultAppFont;
    return _buildTheme(Brightness.light, font);
  }

  /// 构建深色主题
  static ThemeData darkTheme([String? fontId]) {
    final font = fontId != null ? (findAppFontById(fontId) ?? defaultAppFont) : defaultAppFont;
    return _buildTheme(Brightness.dark, font);
  }

  static ThemeData _buildTheme(Brightness brightness, AppFont font) {
    final isDark = brightness == Brightness.dark;

    final cs = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    );

    // 尝试加载 Google Fonts，失败时使用系统回退
    String? resolvedFontFamily;
    try {
      resolvedFontFamily = GoogleFonts.getFont(font.googleFontFamily).fontFamily;
    } catch (_) {
      resolvedFontFamily = null;
    }

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: cs,
      scaffoldBackgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      fontFamily: resolvedFontFamily ?? font.effectiveFont,
      fontFamilyFallback: fontFallbackStack,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : cs.surface,
        foregroundColor: cs.onSurface,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: isDark ? const Color(0xFF1E1E1E) : cs.surfaceContainerLow,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 2,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF2A2A2A) : cs.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      textTheme: _buildTextTheme(base.textTheme, cs.onSurface, cs.onSurfaceVariant),
      dividerTheme: DividerThemeData(
        color: cs.outlineVariant,
        thickness: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : cs.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? const Color(0xFF2A2A2A) : null,
        selectedColor: cs.primaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide.none,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return cs.primary;
          return cs.onSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return cs.primaryContainer;
          return cs.surfaceContainerHighest;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return cs.primary;
          return null;
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: isDark ? const Color(0xFF2A2A2A) : null,
          selectedBackgroundColor: cs.primaryContainer,
          foregroundColor: cs.onSurface,
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(TextTheme base, Color primary, Color secondary) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(color: primary, fontWeight: FontWeight.w700),
      displayMedium: base.displayMedium?.copyWith(color: primary, fontWeight: FontWeight.w700),
      displaySmall: base.displaySmall?.copyWith(color: primary, fontWeight: FontWeight.w600),
      headlineLarge: base.headlineLarge?.copyWith(color: primary, fontWeight: FontWeight.w600),
      headlineMedium: base.headlineMedium?.copyWith(color: primary, fontWeight: FontWeight.w600),
      headlineSmall: base.headlineSmall?.copyWith(color: primary, fontWeight: FontWeight.w600),
      titleLarge: base.titleLarge?.copyWith(color: primary, fontWeight: FontWeight.w600),
      titleMedium: base.titleMedium?.copyWith(color: primary, fontWeight: FontWeight.w500),
      titleSmall: base.titleSmall?.copyWith(color: primary, fontWeight: FontWeight.w500),
      bodyLarge: base.bodyLarge?.copyWith(color: primary, fontWeight: FontWeight.w400, height: 1.5),
      bodyMedium: base.bodyMedium?.copyWith(color: primary, fontWeight: FontWeight.w400, height: 1.5),
      bodySmall: base.bodySmall?.copyWith(color: secondary, fontWeight: FontWeight.w400, height: 1.4),
      labelLarge: base.labelLarge?.copyWith(color: primary, fontWeight: FontWeight.w500),
      labelMedium: base.labelMedium?.copyWith(color: secondary, fontWeight: FontWeight.w500),
      labelSmall: base.labelSmall?.copyWith(color: secondary, fontWeight: FontWeight.w400),
    );
  }
}
